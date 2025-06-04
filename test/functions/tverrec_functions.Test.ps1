Import-Module Pester -MinimumVersion 5.0

BeforeAll {
    Write-Host ("テストスクリプト: {0}" -f $PSCommandPath)
    $targetFile  = $PSCommandPath.Replace('test','src').Replace('.Test.ps1','.ps1')
    Write-Host ("　テスト対象: {0}" -f $targetFile)
    $commonFile  = $targetFile.Replace('tverrec_functions','common_functions')
    . $commonFile
    $script:confDir = '/tmp/conf'
    if (!(Test-Path $script:confDir)) { New-Item -ItemType Directory -Path $script:confDir | Out-Null }

    $script:downloadBaseDir    = '/tmp/download'
    $script:addSeriesName      = $false
    $script:addSeasonName      = $false
    $script:addBroadcastDate   = $false
    $script:addEpisodeNumber   = $false
    $script:videoContainerFormat = 'mp4'
    $script:fileNameLengthMax  = 255
    $script:sortVideoByMedia   = $false
    $script:sortVideoBySeries  = $false

    . $targetFile
    Write-Host ('　テスト対象の読み込みを行いました')
}

Describe 'Format-VideoFileInfo' {
    BeforeEach {
        $script:sortVideoByMedia  = $false
        $script:sortVideoBySeries = $false
    }

    It 'sort設定なしではfileDirがdownloadBaseDirのみとなること' {
        $videoInfo = [PSCustomObject]@{
            seriesName    = 'Series'
            seasonName    = 'Season'
            episodeNum    = 1
            episodeName   = 'Episode'
            mediaName     = 'Media'
            broadcastDate = '2025-04-17'
        }
        Format-VideoFileInfo -videoInfo ([ref]$videoInfo)
        $videoInfo.fileDir | Should -Be '/tmp/download'
    }

    It 'sort設定ありではサブディレクトリが連結されること' {
        $script:sortVideoByMedia  = $true
        $script:sortVideoBySeries = $true
        $videoInfo = [PSCustomObject]@{
            seriesName    = 'Series'
            seasonName    = 'Season'
            episodeNum    = 1
            episodeName   = 'Episode'
            mediaName     = 'Media'
            broadcastDate = '2025-04-17'
        }
        Format-VideoFileInfo -videoInfo ([ref]$videoInfo)
        $videoInfo.fileDir | Should -Be '/tmp/download/Media/Series Season'
    }
}

