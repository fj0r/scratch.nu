use libs *
use common.nu *


export def --env init [] {
    if 'SCRATCH_DB' not-in $env {
        $env.SCRATCH_DB = [$nu.data-dir 'scratch.db'] | path join
    }
    if ($env.SCRATCH_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.SCRATCH_DB
    print $"(ansi grey)created database: $env.SCRATCH_DB(ansi reset)"
    for s in [
        "DROP TABLE _;"
        "CREATE TABLE IF NOT EXISTS person (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            info TEXT default ''
        );"
        "CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            name TEXT NOT NULL,
            alias TEXT NOT NULL DEFAULT '',
            hidden BOOLEAN DEFAULT 0,
            UNIQUE(parent_id, name)
        );"
        "CREATE TABLE IF NOT EXISTS scratch (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            kind TEXT DEFAULT '',
            title TEXT NOT NULL,
            body TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT '',
            deadline TEXT,
            important INTEGER DEFAULT -1,
            urgent INTEGER DEFAULT -1,
            challenge INTEGER DEFAULT -1,
            value REAL DEFAULT 0,
            done BOOLEAN DEFAULT -1,
            relevant INTEGER -- REFERENCES person(id)
        );"
        "CREATE TABLE IF NOT EXISTS scratch_tag (
            scratch_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (scratch_id, tag_id)
        );"
        "CREATE TABLE IF NOT EXISTS kind (
            name TEXT PRIMARY KEY,
            comment TEXT NOT NULL DEFAULT '# ',
            runner TEXT NOT NULL DEFAULT '',
            cmd TEXT NOT NULL DEFAULT '',
            pos INTEGER NOT NULL DEFAULT 1,
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS file (
            hash TEXT PRIMARY KEY,
            body TEXT NOT NULL DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS kind_file (
            kind TEXT NOT NULL,
            hash TEXT NOT NULL,
            path TEXT NOT NULL DEFAULT '.',
            name TEXT NOT NULL,
            ext TEXT NOT NULL
        );"
    ] {
        sqlx $s
    }
    let _ = "
    - name: md
      comment: '# '
      runner: ''
    - name: nu
      comment: '# '
      runner: file
      cmd: 'open {stdin} | nu {}'
    - name: py
      comment: '# '
      runner: file
      cmd: 'open {stdin} | python3 {}'
    - name: js
      comment: '// '
      runner: file
      cmd: node {}
    - name: ts
      comment: '// '
      runner: file
    - name: rs
      comment: '// '
      runner: dir
      cmd: 'cargo build; cargo run'
    - name: hs
      comment: '-- '
      runner: dir
    - name: lua
      comment: '-- '
      runner: file
      cmd: lua {}
    - name: pg
      comment: '-- '
      runner: remote
      cmd: |-
        $env.PGPASSWORD = {password}
        psql -U {username} -d {database} -h {host} -p {port} -f {} --csv
    " | from yaml | each { $in | add-kind }
}


export def --env theme [] {
    $env.SCRATCH_THEME = {
        color: {
            title: default
            id: xterm_grey39
            cat: xterm_lightslategrey
            tag: xterm_wheat4
            important: yellow
            urgent: red
            challenge: blue
            deadline: xterm_rosybrown
            created: xterm_paleturquoise4
            updated: xterm_lightsalmon3a
            body: grey
        }
        symbol: {
            box: [['☐' '🗹' '*'],['[ ]' '[x]' '']]
            md_list: '-'
        }
        formatter: {
            created: {|x| $x | into datetime | date humanize }
            updated: {|x| $x | into datetime | date humanize }
            deadline: {|x, o|
                let t = $x | into datetime
                let s = $t | date humanize
                if ($t - (date now) | into int) > 0 { $s } else { $"!($s)" }
            }
            important: {|x| '' | fill -c '☆ ' -w $x }
            urgent: {|x| '' | fill -c '🔥' -w $x }
            challenge: {|x| '' | fill -c '⚡' -w $x }
        }

    }
}
