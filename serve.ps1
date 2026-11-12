param([switch]$OpenBrowser)

# Use HTTP so the YouTube embed has a referrer.
$root = $PSScriptRoot + [IO.Path]::DirectorySeparatorChar
$url = 'http://localhost:8000/'
$server = New-Object System.Net.HttpListener
$server.Prefixes.Add($url)
try {
    $server.Start()
} catch {
    Write-Error 'Cannot start the website on port 8000. Close the other server and try again.'
    exit 1
}
if ($OpenBrowser) { Start-Process $url }
Write-Output "Website: $url"

try {
    while ($server.IsListening) {
        $request = $server.GetContext()
        $name = [Uri]::UnescapeDataString($request.Request.Url.AbsolutePath).TrimStart('/')
        if (!$name) { $name = 'index.html' }
        $path = [IO.Path]::GetFullPath((Join-Path $root $name))
        $type = switch ([IO.Path]::GetExtension($path)) {
            '.html' { 'text/html; charset=utf-8' }
            '.css'  { 'text/css; charset=utf-8' }
            '.jpg'  { 'image/jpeg' }
        }
        if ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and $type -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            $data = [IO.File]::ReadAllBytes($path)
            $request.Response.ContentType = $type
            $request.Response.ContentLength64 = $data.Length
            $request.Response.OutputStream.Write($data, 0, $data.Length)
        } else {
            $request.Response.StatusCode = 404
        }
        $request.Response.Close()
    }
} finally {
    $server.Close()
}
