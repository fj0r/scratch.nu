export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def sqlx [stmt] {
    open $env.SCRATCH_DB | query db $stmt
}

export def db-upsert [table pk --do-nothing] {
    let r = $in
    let d = if $do_nothing { 'NOTHING' } else {
        $"UPDATE SET ($r| items {|k,v | $"($k)=(Q $v)" } | str join ',')"
    }
    sqlx $"INSERT INTO ($table)\(($r | columns | str join ',')\)
            VALUES\(($r | values | each {Q $in} | str join ',')\)
            ON CONFLICT\(($pk)\) DO ($d);"
}

export def table-upsert [config] {
    let d = $in
    let d = $config.default | merge $d
    let f = $config.filter? | default {}
    $config.default
    | columns
    | reduce -f {} {|i,a|
        let x = $d | get $i
        let x = if ($i in $f) {
            $x | do ($f | get $i) $x
        } else {
            $x
        }
        $a | insert $i $x
    }
    | db-upsert --do-nothing $config.table $config.pk
}

