Param(
    [Parameter()]
    [int]$timeout = 900,
    [Parameter(Mandatory)]
    [string]$puppetdbapitoken,
    [Parameter(Mandatory)]
    [string]$node,
    [Parameter(Mandatory)]
    [string]$puppetmaster
)

$ErrorActionPreference = 'stop'

Function Get-PuppetNodeFact {
    Param(
        [Parameter(Mandatory)]
        [string]$Token,
        [Parameter(Mandatory)]
        [string]$Master,
        [Parameter(Mandatory)]
        [string]$Node,
        [Parameter(Mandatory)]
        [string]$Fact
    )

    # This is a shortcut to the /pdb/query/v4/facts endpoint.
    $hoststr = "https://$master`:8081/pdb/query/v4/nodes/$node/facts/$Fact"
    $headers = @{'X-Authentication' = $Token}

    $result = Invoke-WebRequest -Uri $hoststr -Method Get -Headers $headers -UseBasicParsing
    $content = $result.content | ConvertFrom-Json

    Write-Output $content.value
}

function Disable-SslVerification {
    if (-not ([System.Management.Automation.PSTypeName]"TrustEverything").Type) {
        Add-Type -TypeDefinition  @"
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public static class TrustEverything
{
    private static bool ValidationCallback(object sender, X509Certificate certificate, X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }
    public static void SetCallback() { System.Net.ServicePointManager.ServerCertificateValidationCallback = ValidationCallback; }
    public static void UnsetCallback() { System.Net.ServicePointManager.ServerCertificateValidationCallback = null; }
}
"@
    }
    [TrustEverything]::SetCallback()
}

function Enable-SslVerification {
    if (([System.Management.Automation.PSTypeName]"TrustEverything").Type) {
        [TrustEverything]::UnsetCallback()
    }
}

try {
    # allow system to trust untrusted certs
    Disable-SslVerification
    $lastBootUpTime_current = Get-PuppetNodeFact -Token $puppetdbapitoken -Master $puppetmaster -Node $node -Fact 'lastbootuptime_wmi'

    # create a timespan
    $timespan = New-TimeSpan -Seconds $timeout
    # start a timer
    $stopwatch = [diagnostics.stopwatch]::StartNew()

    while ($stopwatch.elapsed -le $timespan) {
        $lastBootUpTime_now = Get-PuppetNodeFact -Token $puppetdbapitoken -Master $puppetmaster -Node $node -Fact 'lastbootuptime_wmi'
        if ($lastBootUpTime_current -ne $lastBootUpTime_now) {
            $stopwatch.stop()
            exit 0
        }
        Start-Sleep -Seconds 30
    }

    if ($stopwatch.elapsed -ge $timespan) {
        Write-Error "Timeout of $timeout`s has been exceeded. Time elapsed $($stopwatch.Elapsed.Seconds)."
        exit 1
    }
} catch {
    Write-Error $_.Exception.Message
} finally {
    # returns system to normal cert trusting
    Enable-SslVerification
}