#! /usr/bin/env ruby
#
# Check Raid Status
# ===
#
# DESCRIPTION:
#   This plugin provides a method for monitoring the raid array.
#   Further documentation can be found here:
#   https://raid.wiki.kernel.org/index.php/Mdstat#md_config.2Fstatus_line
#   http://linux.die.net/man/4/md
#   https://www.kernel.org/doc/Documentation/md.txt
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#
# #YELLOW
# needs example command
# EXAMPLES:
#
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Yieldbot, Inc  <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

# Exit status codes
EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRIT = 2
exit_code = EXIT_OK

raid_info = '/proc/mdstat'

if File.exist? '/proc/mdstat'
  File.open(raid_info, 'r') do |f|
    @raid_data = f.read.split(/(md[0-9]*)/)
  end
else
  puts '/proc/mdstat is not present'
  exit(exit_code)
end

h = {}
n = 0
k = ''
v = ''

@raid_data.each do |data|
  if n.even? && n != 0
    v = data
    h.store(k, v)
  elsif n.odd?
    k = data
  end
  n += 1
end

h.each do |key, value|
  raid_state = value.split[1]
  total_dev = value.match(/[0-9]*\/[0-9]*/).to_s[0] || 0
  working_dev = value.match(/[0-9]*\/[0-9]*/).to_s[2] || 0
  failed_dev = value.match(/\[[U,_]*\]/).to_s.count '_' || 0
  recovery_state = value.include? 'recovery'

  line_out = "#{key} is #{raid_state}
               #{total_dev} total devices
               #{working_dev} working devices
               #{failed_dev} failed devices"
  # OPTIMIXE
  #   this should/can be written as a switch statement
  if raid_state == 'active' && working_dev >= total_dev && !recovery_state
    puts line_out
  elsif raid_state == 'active' && working_dev < total_dev && recovery_state
    puts line_out.concat " \n\t\t *RECOVERING*"
    exit_code = EXIT_WARNING if exit_code <= EXIT_WARNING
  elsif raid_state == 'active' && working_dev < total_dev && !recovery_state
    puts line_out.concat "\n\t\t *NOT RECOVERING*"
    exit_code = EXIT_CRIT if exit_code <= EXIT_CRIT
  elsif raid_state != 'active'
    puts line_out
    exit_code = EXIT_CRIT if exit_code <= EXIT_CRIT
  end
end
exit(exit_code)
