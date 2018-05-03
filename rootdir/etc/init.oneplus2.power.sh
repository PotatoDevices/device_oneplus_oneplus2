#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

function get-set-forall() {
    for f in $1 ; do
        cat $f
        write $f $2
    done
}

################################################################################

# disable thermal bcl hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
bcl_hotplug_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask 0`
bcl_hotplug_soc_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask 0`
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# some files in /sys/devices/system/cpu are created after the restorecon of
# /sys/. These files receive the default label "sysfs".
restorecon -R /sys/devices/system/cpu

# ensure at most one A57 is online when thermal hotplug is disabled
write /sys/devices/system/cpu/cpu4/online 1
write /sys/devices/system/cpu/cpu5/online 0
write /sys/devices/system/cpu/cpu6/online 0
write /sys/devices/system/cpu/cpu7/online 0

# files in /sys/devices/system/cpu4 are created after enabling cpu4.
# These files receive the default label "sysfs".
# Restorecon again to give new files the correct label.
restorecon -R /sys/devices/system/cpu

# Best effort limiting for first time boot if msm_performance module is absent
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 1248000

# some files in /sysmodule/msm_performance/parameters are created after the restorecon of
# /sys/. These files receive the default label "sysfs".
restorecon -R /sys/module/msm_performance/parameters

# Enable CPU retention
write /sys/module/lpm_levels/system/a53/cpu0/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a53/cpu1/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a53/cpu2/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a53/cpu3/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a57/cpu4/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a57/cpu5/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a57/cpu6/retention/idle_enabled 1
write /sys/module/lpm_levels/system/a57/cpu7/retention/idle_enabled 1

# Enable L2 retention
write /sys/module/lpm_levels/system/a53/a53-l2-retention/idle_enabled 1
write /sys/module/lpm_levels/system/a57/a57-l2-retention/idle_enabled 1

# configure governor settings for little cluster
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 0
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 99
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 0
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/powersave_bias 0
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "85 600000:45 672000:50 768000:55 864000:60 960000:70 1248000:85 1478400:95"
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 20000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 60000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_slack 30000
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 302400

# configure governor settings for big cluster
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay "30000 1248000:60000 1728000:30000"
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 99
 write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 30000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 1248000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/powersave_bias 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads "90 1248000:95"
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 30000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 302400
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_slack 30000

# restore A57's max
copy /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq

# Configure core_ctl module parameters
write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 4
write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 1
write /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres 50
write /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres 30
write /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms  100
write /sys/devices/system/cpu/cpu4/core_ctl/task_thres 4
write /sys/devices/system/cpu/cpu0/core_ctl/not_preferred 0
write /sys/devices/system/cpu/cpu4/core_ctl/is_big_cluster 1
write /sys/devices/system/cpu/cpu4/core_ctl/always_online_cpu "1 0 0 0" 
write /sys/devices/system/cpu/cpu0/core_ctl/max_cpus 4
write /sys/devices/system/cpu/cpu0/core_ctl/min_cpus 4
write /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres 20
write /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres 5
write /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms 100
write /sys/devices/system/cpu/cpu0/core_ctl/task_thres 4
write /sys/devices/system/cpu/cpu0/core_ctl/not_preferred 1
write /sys/devices/system/cpu/cpu0/core_ctl/is_big_cluster 0
write /sys/devices/system/cpu/cpu0/core_ctl/always_online_cpu "1 1 1 1"
chown system:system /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
chown system:system /sys/devices/system/cpu/cpu4/core_ctl/max_cpus

# plugin remaining A57s
write /sys/devices/system/cpu/cpu5/online 1
write /sys/devices/system/cpu/cpu6/online 1
write /sys/devices/system/cpu/cpu7/online 1

# Setting B.L scheduler parameters
write /proc/sys/kernel/sched_migration_fixup 1
write /proc/sys/kernel/sched_small_task 30
write /proc/sys/kernel/sched_upmigrate 90
write /proc/sys/kernel/sched_downmigrate 80
write /proc/sys/kernel/sched_upmigrate_min_nice 8
write /proc/sys/kernel/sched_freq_inc_notify 400000
write /proc/sys/kernel/sched_freq_dec_notify 400000
write /sys/devices/system/cpu/cpu0/sched_mostly_idle_freq 960000
write /sys/devices/system/cpu/cpu0/sched_mostly_idle_load 25
write /sys/devices/system/cpu/cpu0/sched_mostly_idle_nr_run 6

# Enable rps static configuration
write /sys/class/net/rmnet_ipa0/queues/rx-0/rps_cpus 8

# Devfreq
get-set-forall  /sys/class/devfreq/qcom,cpubw*/governor bw_hwmon
restorecon -R /sys/class/devfreq/qcom,cpubw*
get-set-forall  /sys/class/devfreq/qcom,mincpubw.*/governor cpufreq

# Disable sched_boost
write /proc/sys/kernel/sched_boost 0

# set GPU default governor to msm-adreno-tz
write /sys/class/devfreq/fdb00000.qcom,kgsl-3d0/governor msm-adreno-tz
write /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost 0
write /sys/class/kgsl/kgsl-3d0/max_pwrlevel 1
write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 8
write /sys/module/adreno_idler/parameters/adreno_idler_active 1
write /sys/module/adreno_idler/parameters/adreno_idler_downdifferential 20
write /sys/module/adreno_idler/parameters/adreno_idler_idlewait 15 
write /sys/module/adreno_idler/parameters/adreno_idler_idleworkload 3500
write /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 27000000
write /sys/class/kgsl/kgsl-3d0/max_gpuclk 510000000


write /sys/module/cpu_boost/parameters/input_boost_enabled 0

# re-enable thermal and BCL hotplug
write /sys/module/msm_thermal/core_control/enabled 1
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask $bcl_hotplug_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask $bcl_hotplug_soc_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable
