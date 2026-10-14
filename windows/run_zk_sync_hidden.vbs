Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
cmdPath = scriptDir & "\START_ZK_SYNC_AGENT.cmd"

If fso.FileExists(cmdPath) Then
    WshShell.Run Chr(34) & cmdPath & Chr(34), 0
End If

Set fso = Nothing
Set WshShell = Nothing
