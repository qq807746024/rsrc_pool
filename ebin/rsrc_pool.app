{application, rsrc_pool,
	[
    {description, "Resource pool"},
    {vsn, "1.0.1"},
    {modules, [
        resource_pool,
        resource_pool_srv,
        resource_factory
      ]
    },
    {registered, []},
    {applications, [kernel, stdlib]},
    {env, []}
	]
}.
