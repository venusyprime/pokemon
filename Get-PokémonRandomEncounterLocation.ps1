function Get-PokémonRandomEncounterLocation {
<#
.SYNOPSIS
Shows random encounter locations for any given Pokémon for any given version of the game.

.DESCRIPTION
Shows random encounter locations for any given Pokémon for any given version of the game. Will not show gift Pokémon (e.g. Eevee) or one-offs (e.g. Snorlax, Mewtwo).
Can be used to make a checklist of where to catch 'em all.

All credit for data goes to Veekun - https://github.com/veekun

.PARAMETER SpeciesID
National Pokédex number of the Pokémon. Can accept multiple values.

.PARAMETER VersionID
ID for specific game version - see https://github.com/veekun/pokedex/blob/master/pokedex/data/csv/versions.csv

.PARAMETER Path
Path to store CSV files. You'll probably want to edit the script and change the default, since I haven't uploaded the module with Get-OneDrivePath in it yet.

.EXAMPLE
Get-PokémonRandomEncounterLocation -SpeciesID 25 -VersionID 1
Shows random encounter locations for Pikachu in Pokémon Red.

.EXAMPLE
1..151 | Get-PokémonRandomEncounterLocation -VersionID 3
Shows random encounter locations for all 151 Kanto Pokémon in Pokémon Yellow.

.EXAMPLE
Get-PokémonRandomEncounterLocation -Verbose
Shows all random encounter locations for all games. This is not recommended for performance reasons.

.LINK
https://github.com/veekun
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [int32[]]$SpeciesID,
        [int32]$VersionID,
        [string]$Path = (Join-Path -Path (Get-OneDrivePath) -ChildPath "Documents\PowerShell\Pokémon")
    )
    Begin {
        Write-Verbose "Testing $path and creating if necessary."
        if ((Test-Path $Path) -eq $false) {New-Item -Path $Path -ItemType Directory -Force}
    
        $csvs = @("pokemon","encounters","location_areas","locations")
        foreach ($csv in $csvs) {
            Write-Verbose "Testing $csv CSV and downloading if necessary."
            if ((Test-Path $Path\$csv.csv) -eq $false) {Invoke-WebRequest https://github.com/veekun/pokedex/raw/master/pokedex/data/csv/$csv.csv -OutFile $Path\$csv.csv}
            Set-Variable -Name $csv -Value (Import-Csv $path\$csv.csv)
        }
        if ($VersionID) {Write-Verbose "Filtering encounter CSV to version $VersionID"; $encounters = $encounters | where version_id -eq $VersionID}
        $pokemon = $pokemon | where is_default -eq 1
    }
    Process {
        if (!$SpeciesID) {Write-Verbose "No SpeciesID specified, looking at all encounters"; $pokemonencounters  = $encounters}
        else {
            $pokemonencounters = foreach ($ID in $SpeciesID) {
                Write-Verbose "Looking for encounters for species ID $ID"
                $encountervar = $null
                
                $encountervar = $encounters | where Pokemon_ID -eq $ID
                if ($encountervar -eq $null) {
                    Write-Verbose "No encounters for $ID found, generating placeholder"
                    $encountervar = @{pokemon_id = $ID;location_area_id = "NOT FOUND";id = "PLACEHOLDER"}
                }

                $encountervar
            }
        }
        
        
        $customencounters = foreach ($entry in $pokemonencounters) {
            Write-Verbose "Generating custom object for encounter ID $($entry.id) - Pokémon ID $($entry.Pokemon_id)"
            $species = $pokemon | where Species_ID -eq $entry.pokemon_id
            if ($entry.location_area_id -ne "NOT FOUND") {
                $loc_area = $location_areas | where ID -eq $entry.location_area_id
                $loc = $locations | where ID -eq $loc_area.location_id
            }
            else {
                $loc_area = @{Identifier = $null}
                $loc = @{Identifier = "Unknown Location"}
            }
            [PSCustomObject]@{
                SpeciesID = $entry.pokemon_id
                Name = $species.Identifier
                VersionID = $entry.version_id
                Location = $loc.Identifier
                Area = $loc_area.Identifier
            }
        }
        Write-Verbose "Filtering custom objects to only show unique entries"
        $customencounters | select * -Unique
    }
}

Set-Alias -Name Get-PokemonRandomEncounterLocation -Value Get-PokémonRandomEncounterLocation

#3 is yellow's version id - see versions.csv
1..151 | Get-PokémonRandomEncounterLocation -VersionID 3 -Verbose
