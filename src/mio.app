{application, mio,
 [{description, "mio distributed Key-value storage"},
  {vsn, "1"},
  {modules, [mio]},
  {registered, [mio]},
  {applications, [kernel, stdlib]},
  {mod, {mio_app,[]}},
  {debug, false},
  {boot_node, false}
 ]}.
