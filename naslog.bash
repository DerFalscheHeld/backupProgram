#!/bin/bash

# usage:
# 0 0 0 0 * naslog command_tag mail@dest.zz command arg1 arg2

# Extract first argument. Shift moves all aruments down so that $@ contains all other args.
tag=$1
shift

# extract email argument
mail_dest=$1
shift

# Create named pipes. These are pseudo-files which work like normal pipes.
tmp_prefix=/tmp/naslog-$BASHPID
out_fifo=$tmp_prefix-out
err_fifo=$tmp_prefix-err
log_info_fifo=$tmp_prefix-log-info
log_error_fifo=$tmp_prefix-log-error
pipes=($out_fifo $err_fifo $log_info_fifo $log_error_fifo)
mkfifo ${pipes[*]}
both_file=$tmp_prefix-both-file
error_file=$tmp_prefix-error-file

# log log_*_fifo pipes to syslog
systemd-cat -t naslog -p info <$log_info_fifo &
systemd-cat -t naslog -p err <$log_error_fifo &

# add tag to command output and redirect to all necessary pipes
(
    ( sed -u "s/^/[$tag info] /" <$out_fifo | tee $log_info_fifo) &
    ( sed -u "s/^/[$tag err ] /" <$err_fifo | tee $log_error_fifo $error_file ); wait
) >$both_file &

# Call the program that the user requested.
# piping: $@ writes stdout directly to out_fifo. 2>&1 forwards stderr to output of subshell. Note: the order of "2>&1 1>" is important!
( "$@" 2>&1 1>$out_fifo || echo "$1 exited with return value $?. Command: $@" ) >$err_fifo

# If the program finished, wait for all pipe handlers to finish as well. They should receive EOL after $@ finished and terminate themselves.
wait

# if errors encountered: send email
if [[ -s $error_file ]]; then
    ( echo "Error log:"; cat $both_file ) | cat -v | mail -s "[$HOSTNAME] Error in $tag: $(head -1 $error_file)" $mail_dest 
fi

# clean up named pipes
rm ${pipes[*]} $both_file $error_file
