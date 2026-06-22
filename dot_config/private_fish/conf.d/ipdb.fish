# Set ipdb as the breakpoint debugger
function IPDB_ON
    set -gx PYTHONBREAKPOINT 'ipdb.set_trace'
end

function IPDB_OFF
    set -e PYTHONBREAKPOINT
end
