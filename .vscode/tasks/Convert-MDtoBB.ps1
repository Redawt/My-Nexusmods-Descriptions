param(
    [Parameter(Mandatory = $true)]
    [string]$mdFile
)


function Main() {
    if ((Get-Item $mdFile).Extension -ne ".md") {
        Write-Error "The file is not a markdown file: $mdFile"
        Exit
    }

    $gameName = (Get-Item $mdFile).Directory.Name 
    $targetPathBB = Join-Path "." "bbcode" $gameName "$((get-item $mdFile).BaseName).txt"
    $targetPathMD = Join-Path "." "gh-preview" $gameName (get-item $mdFile).name

    # Read the content of the Markdown file
    $content = Get-Content -Path $mdFile -Raw

    $output = Replace-MDCode -text $content -regexConv $BBcodereplacements

    # Write the content to the bbcode text file
    $output | Set-Content -Path $targetPathBB
    
    $output = Replace-MDCode -text $content -regexConv $MDcodereplacements

    # Write the content to the github preview markdown file
    $output | Set-Content -Path $targetPathMD


    return

}




$BBcodereplacements = @(
    # Bold Text
    @('\*\*(.*?)\*\*', "[b]`$1[/b]"),
    @('__(.*?)__', "[u]`$1[/u]"),
    # Heading 3
    # @("(?m)^###\s*(.+?)\s*$", "[size=4][b]`$1[/b][/size]"),
    @("(?m)^###\s*(.+?)\s*?$", "[size=4][b]`$1[/b][/size]"),
    # Heading 2
    # @("(?m)^##\s*(.+?)\s*$", "[size=5][b]`$1[/b][/size]"),
    @("(?m)^##\s*(.+?)\s*?$", "[size=5][b]`$1[/b][/size]"),
    # Heading 1
    # @("(?m)^#\s*(.+?)\s*$", "[size=6][b]`$1[/b][/size]"),
    @("(?m)^#\s*(.+?)\s*?$", "[size=6][b]`$1[/b][/size]"),
    # List points
    @("(?m)^\*\s(.+?)$", "[*]`$1"),
    # Line 
    @('---', '[line]')
    # Center: -> <- (multiline)
    @('->(?s)(.*?)<-', "[center]`$1[/center]"),
    # Font Sizes (Nexus, multiline)
    @('-small-(?s)(.*?)-small-', "[size=2]`$1[/size]"),
    @('-normal-(?s)(.*?)-normal-', "[size=3]`$1[/size]"),
    @('-big-(?s)(.*?)-big-', "[size=4]`$1[/size]"),
    @('-very big-(?s)(.*?)-very big-', "[size=5]`$1[/size]"),
    @('-extra big-(?s)(.*?)-extra big-', "[size=6]`$1[/size]"),
    # Arial Fontt 
    @('-arial-(?s)(.*?)-arial-', "[font=Arial]`$1[/font]"),
    # Strikethrough
    @('~~(.*?)~~', "[strike]`$1[/strike]"),
    # Italics
    @('\*(.*?)\*', '[i]$1[/i]'),
    @('_(.*?)_', '[i]$1[/i]'),
    # Image with link
    @("\[!\[(.*?)\]\((https?:\/\/[^\)]+)\)\]\((https?:\/\/[^\)]+)\)", "[url=`$3][img]`$2[/img][/url]"),
    # Image
    @('!\[([^\]]*?)\]\(([^\)]*?)\)', "[img]`$2[/img]"),
    # Link
    @('\[([^\]]*?)\]\(([^\)]*?)\)', "[url=`$2]`$1[/url]"),
    # Code Block
    @('```(\s*[\s\S]*?\s*)```', '[code]$1[/code]'),
    @('(?m)(^(\[\*\].*\r?\n?)+)', '[list]$1[/list]'),
    # Mono Highlight
    @('`([^`]*?)`', "[mono]`$1[/mono]"),
    # Quote Block
    @('((?:^\> .*$\n?)+)', "[quote]`n`$1[/quote]\n"),
    # Text Highlighting
    # @('==([^=]+)==', "[color=#ff7700][b]`$1[/b][/color]"),
    @('==lsb=([^=]+)=lsb==', "[color=#c9daf8][b]`$1[/b][/color]"), # light steel blue bold
    @('=lsb=([^=]+)=lsb=', "[color=#c9daf8]`$1[/color]"), # light steel blue
    @('=lb=([^=]+)=lb=', "[color=#00ffff]`$1[/color]"), # light blue
    @('==([^=]+)==', "[color=#d98f40][b]`$1[/b][/color]"), # normal orange-y highlight bold
    # Embedded Youtube Video (GitHub style)
    # @("(?m)^(?:\r?\n)?(https:\/\/(?:www\.)?youtube\.com\/watch\?v=[\w-]+|https:\/\/youtu\.be\/[\w-]+)(?:\r?\n)?", "`n[youtube]`$1[/youtube]`n"),
    # @("(?m)^https:\/\/www\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})$", "`n[youtube]`$1[/youtube]`n"),    
    @("(?m)https:\/\/www\.youtube\.com\/watch\?v=(.+?)\s*?$", "[youtube]`$1[/youtube]"),
    # Spoiler Tags
    @('\|\|(?s)(.*?)\|\|', "[spoiler]`$1[/spoiler]"),
    # Quotes
    @("(?m)^>\s*(.+?)\s*$","[quote]`$1[/quote]"),
    @('^> ', '')

)

$MDcodereplacements = @(
    @('->(?s)(.*?)<-', "`$1"),
    @('-small-(?s)(.*?)-small-', "`$1"),
    @('-normal-(?s)(.*?)-normal-', "`$1"),
    @('-big-(?s)(.*?)-big-', "`$1"),
    @('-very big-(?s)(.*?)-very big-', "`$1"),
    @('-extra big-(?s)(.*?)-extra big-', "`$1"),
    @('__(.*?)__', "<ins>`$1</ins>"),
    # Arial Font
    @('-arial-(?s)(.*?)-arial-', "`$1"),
    # Spoiler Tags
    @('\|\|(?s)(.*?)\|\|', "`$1"),
    @('==lsb=([^=]+)=lsb==', "**`$1**"), # light steel blue bold
    @('=lsb=([^=]+)=lsb=', "**`$1**"), # light steel blue
    @('=lb=([^=]+)=lb=', "**`$1**"), # light blue
    @('==([^=]+)==', "**`$1**")
)



function Replace-MDCode {
    param (
        [string]$text,
        [array]$regexConv    
    )

    foreach ($replacement in $regexConv) {
        $pattern = $replacement[0]
        $replace = $replacement[1]
        try {
            $text = $text -replace $pattern, $replace 
        }
        catch {
            Write-Output $replacement[0]
            Write-Output $replacement[1]
        }
    }

    return $text
}


Main
exit