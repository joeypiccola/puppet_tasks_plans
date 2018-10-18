plan lastbootuptime_win::reboot_demo_one(
  TargetSpec $server,
  String $worker
  String $token
) {

  $lastbootuptime_1 = run_command('systeminfo | find "System Boot Time:"', $server)
  notice($lastbootuptime_1)

  # Reboot the servers
  run_task('reboot', $server)


  $taskargs = { 'puppetdbapitoken' => $token,
                'node'             => $server,
                'puppetmaster'     => 'puppet.piccola.us' }

  run_task('lastbootuptime_win::wait_lastbootuptime', $worker, 'some phony description', $taskargs)

  $lastbootuptime_2 = run_command('systeminfo | find "System Boot Time:"', $server)
  notice($lastbootuptime_2)
}

# bolt plan run lastbootuptime_win::reboot_demo_one server=den3-node-4.ad.piccola.us worker=sea1-node-1.ad.piccola.us -token=**
