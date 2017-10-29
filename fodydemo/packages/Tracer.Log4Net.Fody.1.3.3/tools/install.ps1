﻿param($installPath, $toolsPath, $package, $project)

$AdapterAssembly = "Tracer.Log4Net"
$LogManager = "Tracer.Log4Net.Adapters.LogManagerAdapter"
$Logger = "Tracer.Log4Net.Adapters.LoggerAdapter"
$StaticLogger = "Tracer.Log4Net.Log"

function RemoveForceProjectLevelHack($project)
{
    Write-Host "RemoveForceProjectLevelHack" 
	Foreach ($item in $project.ProjectItems) 
	{
		if ($item.Name -eq "Fody_ToBeDeleted.txt")
		{
			$item.Delete()
		}
	}
}

function FlushVariables()
{
    Write-Host "Flushing environment variables"
    $env:FodyLastProjectPath = ""
    $env:FodyLastWeaverName = ""
    $env:FodyLastXmlContents = ""
}

function Update-FodyConfig($addinName, $project)
{
	Write-Host "Update-FodyConfig" 
    $fodyWeaversPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($project.FullName), "FodyWeavers.xml")

	$FodyLastProjectPath = $env:FodyLastProjectPath
	$FodyLastWeaverName = $env:FodyLastWeaverName
	$FodyLastXmlContents = $env:FodyLastXmlContents
	
	if (
		($FodyLastProjectPath -eq $project.FullName) -and 
		($FodyLastWeaverName -eq $addinName))
	{
        Write-Host "Upgrade detected. Restoring content for $addinName"
		[System.IO.File]::WriteAllText($fodyWeaversPath, $FodyLastXmlContents)
        FlushVariables
		return
	}
	
    FlushVariables

    $xml = [xml](get-content $fodyWeaversPath)

    $weavers = $xml["Weavers"]
    $node = $weavers.SelectSingleNode($addinName)

    if (-not $node)
    {
        Write-Host "Appending node"
        $newNode = $xml.CreateElement($addinName)
		$newNode.SetAttribute("adapterAssembly", $AdapterAssembly)
		$newNode.SetAttribute("logManager", $LogManager)
		$newNode.SetAttribute("logger", $Logger)
		$newNode.SetAttribute("staticLogger", $StaticLogger)
        $newNode.SetAttribute("traceConstructors", "false")
        $newNode.SetAttribute("traceProperties", "true")
		
		$traceOnNode = $xml.CreateElement("TraceOn")
		$traceOnNode.SetAttribute("class", "public") 
		$traceOnNode.SetAttribute("method", "public") 
		
		$newNode.AppendChild($traceOnNode)
        $weavers.AppendChild($newNode)
    }

    $xml.Save($fodyWeaversPath)
}

function Fix-ReferencesCopyLocal($package, $project)
{
    Write-Host "Fix-ReferencesCopyLocal $($package.Id)"
    $asms = $package.AssemblyReferences | %{$_.Name}
 
    foreach ($reference in $project.Object.References)
    {
        if ($asms -contains $reference.Name + ".dll")
        {
            if($reference.CopyLocal -eq $false)
            {
                $reference.CopyLocal = $true;
            }
        }
    }
}

function UnlockWeaversXml($project)
{
    $fodyWeaversProjectItem = $project.ProjectItems.Item("FodyWeavers.xml");
    if ($fodyWeaversProjectItem)
    {
        $fodyWeaversProjectItem.Open("{7651A701-06E5-11D1-8EBD-00A0C90F26EA}")
        $fodyWeaversProjectItem.Save()
		$fodyWeaversProjectItem.Document.Close()
    }   
}

UnlockWeaversXml($project)

RemoveForceProjectLevelHack $project

Update-FodyConfig "Tracer" $project

Fix-ReferencesCopyLocal $package $project