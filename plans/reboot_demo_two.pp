plan lastbootuptime_win::reboot_demo_two(
  TargetSpec $server,
) {

  $lastbootuptime_1 = run_command('systeminfo | find "System Boot Time:"', $server)
  notice($lastbootuptime_1)

  # Reboot the servers
  run_task('reboot', $server)

  reboot::wait([$server], { 'disconnect_wait' => 300 })

  $lastbootuptime_2 = run_command('systeminfo | find "System Boot Time:"', $server)
  notice($lastbootuptime_2)
}

# bolt plan run lastbootuptime_win::reboot_demo_two server=den3-node-4.ad.piccola.us
