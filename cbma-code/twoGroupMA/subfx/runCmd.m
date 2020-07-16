function [status, result] = runCmd(cmdStr)
% wrapper for system() to run a system command using a login shell
%
% this causes paths and variables established in .bash_profile
% to be available, making it possible to run FSL utilities

[status, result] = system(sprintf('bash -l -c ''%s''', cmdStr));








