[System.Diagnostics.Process]::Start("cmd", "/K cd c:\src\GitHub\Blog & hexo generate --watch")
[System.Diagnostics.Process]::Start("cmd", "/K cd c:\src\GitHub\Blog & hexo server --open")
[System.Diagnostics.Process]::Start("code", "c:\src\GitHub\Blog")

