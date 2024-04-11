#!/usr/bin/env -S julia --startup-file=no

const mu_repo = "https://github.com/djcb/mu.git"

const mu4e_versions =
    [v"1.0" => "v1.0",
     v"1.8" => "v1.8.15",
     v"1.10" => "v1.10.8",
     v"1.12" => "v1.12.3"]

const mu_dir = joinpath(tempdir(), "jl_mu_symbol_extract")

isdir(mu_dir) || run(`git clone $mu_repo $mu_dir`)

const mu4e_symbols = Dict{VersionNumber, Set{String}}()

const mu4e_rename_rules =
    [r"^mu4e~" => "mu4e--",
     r"^mu4e~proc" => "mu4e--server-", # In 1.0 => 1.8
     r"^mu4e--" => "mu4e-",
     r"^mu4e-" => "mu4e--"]

function find_mu4e_symbols(file)
    content = read(file, String)
    symbols = String[]
    for (; captures) in eachmatch(r"\((?:cl-)?def(?:un|var|custom|const|face) +(mu4e[^( \n]+)", content)
        push!(symbols, String(first(captures)))
    end
    symbols
end

for (version, tag) in mu4e_versions
    @info "Searching for symbols in $tag"
    symbols = String[]
    run(Cmd(`git checkout $tag`, dir=mu_dir))
    elisp_files = readdir(joinpath(mu_dir, "mu4e"), join=true)
    for file in elisp_files
        endswith(file, ".el") || continue
        append!(symbols, find_mu4e_symbols(file))
    end
    mu4e_symbols[version] = Set(symbols)
end

const mu4e_renames = Dict{Pair{VersionNumber, VersionNumber},
                          Vector{Pair{String, String}}}()

for iold in 1:length(mu4e_versions)-1
    for inew in iold+1:length(mu4e_versions)
        vold, vnew = first.(mu4e_versions[[iold, inew]])
        olds, news = mu4e_symbols[vold], mu4e_symbols[vnew]
        renames = Pair{String, String}[]
        for symold in olds
            for rule in mu4e_rename_rules
                trynew = replace(symold, rule)
                if symold != trynew && trynew in news && !(trynew in olds)
                    push!(renames, symold => trynew)
                end
            end
        end
        mu4e_renames[vold => vnew] = renames
    end
end

for version in first.(mu4e_versions)
    fname = "mu4e-compat-$(version.major).$(version.minor).el"
    open(joinpath(@__DIR__, fname), "w") do io
        print(io, ";;; $fname -*- lexical-binding: t; -*-\n\n",
              "(setq mu4e-compat--needlessly-breaking-renames-sofar\n",
              "      '(")
        all_renames_past = Set{String}()
        oldvers = filter(<=(version), sort(first.(mu4e_versions)))
        firstentry = true
        for i in 1:length(oldvers)-1
            for j in i:length(oldvers)
                renames = get(mu4e_renames, oldvers[i] => oldvers[j], String[])
                renames = setdiff(renames, all_renames_past)
                all_renames_past = all_renames_past ∪ renames
                isempty(renames) && continue
                if firstentry
                    firstentry = false
                else
                    print(io, "\n        ")
                end
                print(io, "(\"$(oldvers[j].major).$(oldvers[j].minor)", '"')
                for (from, to) in renames
                    print(io, "\n         ($from . $to)")
                end
                print(io, ")")
            end
        end
        print(io, "))\n\n",
              "(setq mu4e-compat--needlessly-breaking-renames-future\n",
              "      '(")
        all_renames_future = Set{String}()
        newvers = filter(>=(version), sort(first.(mu4e_versions)))
        firstentry = true
        for i in 1:length(newvers)-1
            for j in i:length(newvers)
                renames = get(mu4e_renames, newvers[i] => newvers[j], String[])
                renames = setdiff(renames, all_renames_future)
                all_renames_future = all_renames_future ∪ renames
                isempty(renames) && continue
                if firstentry
                    firstentry = false
                else
                    print(io, "\n        ")
                end
                print(io, "(\"$(newvers[j].major).$(newvers[j].minor)", '"')
                for (from, to) in renames
                    print(io, "\n         ($from . $to)")
                end
                print(io, ")")
            end
        end
        println(io, "))\n\n;;; $fname ends here")
    end
end
