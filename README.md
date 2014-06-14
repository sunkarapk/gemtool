```
Usage: gemtool [actions | [options] commands]

  Commands:
    -i, --install FILE               Install the gems from the given gem list
    -u, --uninstall FILE             Uninstall the gems from the given gem list
    -t, --update                     Updates all the outdated gems
    -p, --prune                      Removes all the older versions of gems while keeping that latest intact
    -c, --clean FILE                 Make your gem list equal to given gem list

  Actions:
    -v, --version                    Version of gemtool
    -h, --help                       Display this screen

  Options:
    -d, --[no-]doc                   Install documentation (default false)
    -s, --source URL                 Use URL as the remote source for gems
```