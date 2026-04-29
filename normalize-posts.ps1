$ErrorActionPreference = 'Stop'

function Convert-CodeBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Code,

        [Parameter()]
        [string] $Language = 'powershell'
    )

    $normalized = $Code -replace '<br\s*/?>', "`r`n"
    $normalized = [System.Net.WebUtility]::HtmlDecode($normalized).Trim()
    $normalized = [System.Net.WebUtility]::HtmlEncode($normalized)

    return "<pre class=`"wp-code language-$Language`"><code>`r`n$normalized`r`n</code></pre>"
}

function Convert-CaptionBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Body
    )

    $normalizedBody = $Body.Trim()

    if ($normalizedBody -match '^(?<media>(?:<a\b.*?</a>|<img\b[^>]*>))(?:\s*(?<text>.*))?$') {
        $media = $matches['media'].Trim()
        $captionText = $matches['text'].Trim()

        if ($captionText) {
            return "<p>$media</p>`r`n<p class=`"wp-caption-text`">$captionText</p>"
        }

        return "<p>$media</p>"
    }

    return "<p>$normalizedBody</p>"
}

$postFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot '_posts') -Filter '*.html' -File
$updatedCount = 0

foreach ($postFile in $postFiles) {
    $original = Get-Content -Path $postFile.FullName -Raw
    $updated = $original

    if ($postFile.Name -match '^2016-(02-04|03-10|03-11|04-02|04-18|04-28|04-29|05-18|08-23)-(powershell-and-visio|introducing-visiobot3000|translating-visio-vba-to-powershell|visiobot3000-settings-import)') {
        $frontMatterMatch = [regex]::Match($updated, '^(?s)(---\r?\n.*?\r?\n---\r?\n)(.*)$')
        if ($frontMatterMatch.Success) {
            $frontMatter = $frontMatterMatch.Groups[1].Value
            $body = $frontMatterMatch.Groups[2].Value
            $body = [System.Net.WebUtility]::HtmlDecode($body)
            $body = $body -replace '</a></p>\s*<p>', "</a>`r`n<p>"
            $body = $body -replace '(?m)^</code></pre>\r?\n(?=<(?:pre|a|p|h[1-6]|ul|ol|blockquote|div))', ''
            $body = [regex]::Replace(
                $body,
                '(?s)(<pre class="wp-code language-powershell"><code>.*?)(<p>\s*(?:#|\$|\{|\}|[A-Za-z]+-[A-Za-z][^<]*?))</p>',
                {
                    param($match)
                    $prefix = $match.Groups[1].Value
                    $line = $match.Groups[2].Value -replace '^<p>', ''
                    $line = $line.TrimEnd()
                    "$prefix`r`n$line"
                }
            )
            $body = [regex]::Replace(
                $body,
                '(?s)(<pre class="wp-code language-powershell"><code>.*?)(?=<(?:a|h[1-6]|ul|ol|blockquote|div))',
                '$1' + "`r`n</code></pre>`r`n"
            )
            $body = [regex]::Replace(
                $body,
                '(?s)(<pre class="wp-code language-powershell"><code>.*?)(?=<p>(?!\s*(?:#|\$|\{|\}|[A-Za-z]+-[A-Za-z])))',
                '$1' + "`r`n</code></pre>`r`n"
            )
            $body = [regex]::Replace(
                $body,
                '(?s)<pre class="wp-code language-powershell"><code>(.*?)</code></pre>',
                {
                    param($match)
                    $code = $match.Groups[1].Value
                    $code = $code -replace '<br\s*/?>', "`r`n"
                    $code = $code -replace '</p>\s*<p>', "`r`n`r`n"
                    $code = $code -replace '<p>', ''
                    $code = $code -replace '</p>', ''
                    $code = $code.Trim()
                    "<pre class=`"wp-code language-powershell`"><code>`r`n$code`r`n</code></pre>"
                }
            )
            $body = $body -replace '(?m)^\s*</code></pre>\r?\n(?=\s*<(?:a|p|h[1-6]|ul|ol|blockquote|div))', ''
            $updated = $frontMatter + $body
        }
    }

    $updated = $updated -replace '<p><!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4\.0 Transitional//EN" "http://www\.w3\.org/TR/REC-html40/loose\.dtd"><br\s*/?>\s*', ''
    $updated = $updated -replace '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4\.0 Transitional//EN" "http://www\.w3\.org/TR/REC-html40/loose\.dtd"><br\s*/?>\s*', ''
    $updated = $updated -replace '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4\.0 Transitional//EN" "http://www\.w3\.org/TR/REC-html40/loose\.dtd">\s*', ''
    $updated = $updated -replace '<html><body></p>\s*', ''
    $updated = $updated -replace '<html><body><br\s*/?>\s*', ''
    $updated = $updated -replace '<html><body>\s*', ''
    $updated = $updated -replace '</body></html>', ''

    $updated = [regex]::Replace(
        $updated,
        '(?s)<p>\[powershell\]\s*(.*?)\s*\[/powershell\]</p>',
        { param($match) Convert-CodeBlock -Code $match.Groups[1].Value }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)\[powershell\]\s*(.*?)\s*\[/powershell\]',
        { param($match) Convert-CodeBlock -Code $match.Groups[1].Value }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)\[powershell\]\s*(.*?)\s*</code></pre>',
        { param($match) Convert-CodeBlock -Code $match.Groups[1].Value }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)&lt;p&gt;\[powershell\]\s*(.*?)\s*(?:\[/powershell\]|</code></pre>)',
        { param($match) Convert-CodeBlock -Code $match.Groups[1].Value }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)<p>\[(?:vbnet|vb)[^\]]*\][\s\r\n]*(.*?)[\s\r\n]*\[/(?:vbnet|vb)\](?:<br\s*/?>)?</p>',
        { param($match) Convert-CodeBlock -Code $match.Groups[1].Value -Language 'vbnet' }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)\[(?:vbnet|vb)[^\]]*\][\s\r\n]*(.*?)[\s\r\n]*\[/(?:vbnet|vb)\]',
        { param($match) Convert-CodeBlock -Code $match.Groups[1].Value -Language 'vbnet' }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)<p>\[caption[^\]]*\](.*?)\[/caption\](?:<br\s*/?>)?</p>',
        { param($match) Convert-CaptionBlock -Body $match.Groups[1].Value }
    )

    $updated = [regex]::Replace(
        $updated,
        '(?s)\[caption[^\]]*\](.*?)\[/caption\]',
        { param($match) Convert-CaptionBlock -Body $match.Groups[1].Value }
    )

    $updated = $updated -replace '\[/powershell\]', ''
    $updated = $updated -replace '\[/(?:vbnet|vb)\]', ''
    $updated = $updated -replace '<p><pre class="wp-code language-powershell"><code>', '<pre class="wp-code language-powershell"><code>'
    $updated = $updated -replace '</code></pre></p>', '</code></pre>'
    $updated = $updated -replace '<p><pre class="wp-code language-vbnet"><code>', '<pre class="wp-code language-vbnet"><code>'

    $updated = [regex]::Replace(
        $updated,
        '(?s)<pre class="wp-code language-(powershell|vbnet)"><code>(.*?)</code></pre>',
        {
            param($match)

            $language = $match.Groups[1].Value
            $code = $match.Groups[2].Value
            $code = $code -replace '&lt;/p&gt;\s*&lt;p&gt;', "`r`n"
            $code = $code -replace '&lt;/p&gt;', ''
            $code = $code -replace '&lt;p&gt;', ''
            $code = $code -replace '</p>\s*<p>', "`r`n"
            $code = $code -replace '<p>', ''
            $code = $code -replace '</p>', ''
            $code = $code.Trim()

            "<pre class=`"wp-code language-$language`"><code>`r`n$code`r`n</code></pre>"
        }
    )

    while ($updated -match '<a href="([^"]+)">([^<]+)</a><a href="\1">([^<]+)</a>') {
        $updated = [regex]::Replace(
            $updated,
            '<a href="([^"]+)">([^<]+)</a><a href="\1">([^<]+)</a>',
            '<a href="$1">$2$3</a>'
        )
    }

    $updated = $updated -replace '(?m)^<p>\s*</p>\r?\n?', ''

    while ($updated -match '(?s)(<pre class="wp-code language-powershell"><code>.*?)(\r?\n\r?\n)(?=<(?:a|p|h[1-6]|ul|ol|blockquote|div))') {
        $updated = [regex]::Replace(
            $updated,
            '(?s)(<pre class="wp-code language-powershell"><code>.*?)(\r?\n\r?\n)(?=<(?:a|p|h[1-6]|ul|ol|blockquote|div))',
            '$1' + "`r`n</code></pre>`r`n",
            1
        )
    }

    while ($updated -match '(?s)(<pre class="wp-code language-vbnet"><code>.*?)(\r?\n\r?\n)(?=<(?:a|p|h[1-6]|ul|ol|blockquote|div))') {
        $updated = [regex]::Replace(
            $updated,
            '(?s)(<pre class="wp-code language-vbnet"><code>.*?)(\r?\n\r?\n)(?=<(?:a|p|h[1-6]|ul|ol|blockquote|div))',
            '$1' + "`r`n</code></pre>`r`n",
            1
        )
    }

    if ($updated -ne $original) {
        Set-Content -Path $postFile.FullName -Value $updated
        $updatedCount++
    }
}

Write-Output "Updated $updatedCount post files."