# Screen Timeout Tray - Windows 11 / Windows PowerShell 5.1
# Changes only the screen-off timeout of the active Windows power plan.
# No third-party modules or administrator privileges normally required.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Choices = [ordered]@{
    '1 minute' = 1; '2 minutes' = 2; '3 minutes' = 3
    '5 minutes' = 5; '10 minutes' = 10; '15 minutes' = 15
    '20 minutes' = 20; '25 minutes' = 25; '30 minutes' = 30
    '45 minutes' = 45; '1 hour' = 60; '2 hours' = 120
    '3 hours' = 180; '4 hours' = 240; '5 hours' = 300
    'Never' = 0
}

# /query prints the active plan's AC and DC indexes in hexadecimal.
# Looking for hex indexes instead of English labels also works on non-English Windows.
function Get-Timeouts {
    $lines = & powercfg.exe /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Couldn't read Windows display timeout settings: $($lines -join ' ')" }
    $values = [regex]::Matches(($lines -join "`n"), '0x[0-9a-fA-F]+')
    if ($values.Count -lt 2) { throw 'Unable to parse the display timeout values from powercfg.' }
    # Seconds are stored by Windows; the UI offers whole-minute presets.
    return @{
        AC = [int]([Convert]::ToUInt32($values[$values.Count - 2].Value.Substring(2), 16) / 60)
        DC = [int]([Convert]::ToUInt32($values[$values.Count - 1].Value.Substring(2), 16) / 60)
    }
}

function Set-Timeout([string]$Power, [int]$Minutes) {
    $option = if ($Power -eq 'AC') { 'monitor-timeout-ac' } else { 'monitor-timeout-dc' }
    $result = & powercfg.exe /change $option $Minutes 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Windows rejected the change: $($result -join ' ')" }
}

function Format-Timeout([int]$Minutes) {
    foreach ($name in $script:Choices.Keys) {
        if ($script:Choices[$name] -eq $Minutes) { return $name }
    }
    if ($Minutes -eq 0) { return 'Never' }
    return "$Minutes min (custom)"
}

# Generate the icon in memory: no external assets required.
$bitmap = New-Object System.Drawing.Bitmap(64, 64)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)
$blue = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(41, 125, 226))
$white = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 5)
$graphics.FillRectangle($blue, 4, 9, 56, 42)
$graphics.DrawRectangle($white, 10, 15, 44, 30)
$graphics.DrawLine($white, 32, 51, 32, 58)
$graphics.DrawLine($white, 20, 58, 44, 58)
$icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
$graphics.Dispose()
$blue.Dispose()
$white.Dispose()

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $icon
$notify.Text = 'Screen Timeout Tray'
$notify.Visible = $true

$window = New-Object System.Windows.Forms.Form
$window.Text = 'Screen Timeout Tray'
$window.ClientSize = New-Object System.Drawing.Size(390, 222)
$window.FormBorderStyle = 'FixedDialog'
$window.MaximizeBox = $false
$window.StartPosition = 'CenterScreen'
$window.Icon = $icon
$window.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$heading = New-Object System.Windows.Forms.Label
$heading.Text = 'Screen turns off after'
$heading.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$heading.SetBounds(18, 18, 340, 28)
$window.Controls.Add($heading)

$batteryLabel = New-Object System.Windows.Forms.Label
$batteryLabel.Text = 'On battery'
$batteryLabel.SetBounds(20, 62, 155, 22)
$window.Controls.Add($batteryLabel)

$pluggedLabel = New-Object System.Windows.Forms.Label
$pluggedLabel.Text = 'Plugged in'
$pluggedLabel.SetBounds(203, 62, 155, 22)
$window.Controls.Add($pluggedLabel)

$batteryCombo = New-Object System.Windows.Forms.ComboBox
$pluggedCombo = New-Object System.Windows.Forms.ComboBox
foreach ($combo in @($batteryCombo, $pluggedCombo)) {
    $combo.DropDownStyle = 'DropDownList'
    $combo.SetBounds($(if ($combo -eq $batteryCombo) {20} else {203}), 88, 164, 28)
    foreach ($name in $script:Choices.Keys) { [void]$combo.Items.Add($name) }
    $window.Controls.Add($combo)
}

$apply = New-Object System.Windows.Forms.Button
$apply.Text = 'Apply'
$apply.SetBounds(277, 144, 91, 31)
$window.Controls.Add($apply)

$refresh = New-Object System.Windows.Forms.Button
$refresh.Text = 'Refresh'
$refresh.SetBounds(178, 144, 91, 31)
$window.Controls.Add($refresh)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Changes affect the active Windows power plan.'
$status.ForeColor = [System.Drawing.Color]::DimGray
$status.SetBounds(20, 189, 350, 24)
$window.Controls.Add($status)

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$batteryMenu = New-Object System.Windows.Forms.ToolStripMenuItem('On battery')
$pluggedMenu = New-Object System.Windows.Forms.ToolStripMenuItem('Plugged in')
[void]$menu.Items.Add($batteryMenu)
[void]$menu.Items.Add($pluggedMenu)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$openItem = New-Object System.Windows.Forms.ToolStripMenuItem('Open settings window')
$windowsItem = New-Object System.Windows.Forms.ToolStripMenuItem('Windows power settings')
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
[void]$menu.Items.Add($openItem)
[void]$menu.Items.Add($windowsItem)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
[void]$menu.Items.Add($exitItem)
$notify.ContextMenuStrip = $menu

$script:MenuItems = @{ AC = @{}; DC = @{} }
foreach ($power in @('DC', 'AC')) {
    $parent = if ($power -eq 'DC') { $batteryMenu } else { $pluggedMenu }
    foreach ($label in $script:Choices.Keys) {
        $value = [int]$script:Choices[$label]
        $item = New-Object System.Windows.Forms.ToolStripMenuItem($label)
        $item.Tag = @{ Power = $power; Minutes = $value }
        $item.Add_Click({
            $info = $this.Tag
            try {
                Set-Timeout $info.Power $info.Minutes
                Sync-UI
                $status.Text = 'Updated successfully.'
            } catch {
                [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Screen Timeout Tray', 'OK', 'Error') | Out-Null
            }
        })
        [void]$parent.DropDownItems.Add($item)
        $script:MenuItems[$power][$value] = $item
    }
}

function Sync-UI {
    $current = Get-Timeouts
    foreach ($power in @('AC', 'DC')) {
        $minutes = [int]$current[$power]
        $combo = if ($power -eq 'AC') { $pluggedCombo } else { $batteryCombo }
        $label = Format-Timeout $minutes
        if (-not $script:Choices.Contains($label)) {
            # Retain a custom value if someone changed Windows Settings externally.
            if (-not $combo.Items.Contains($label)) { [void]$combo.Items.Add($label) }
        }
        $combo.SelectedItem = $label
        foreach ($key in $script:MenuItems[$power].Keys) {
            $script:MenuItems[$power][$key].Checked = ($key -eq $minutes)
        }
    }
    $notify.Text = 'Screen timeout: battery ' + (Format-Timeout $current.DC) + ', AC ' + (Format-Timeout $current.AC)
    # Tooltip text is limited to 63 characters on Windows; clip safely.
    if ($notify.Text.Length -gt 63) { $notify.Text = $notify.Text.Substring(0, 63) }
}

$apply.Add_Click({
    try {
        foreach ($entry in @(@('DC', $batteryCombo), @('AC', $pluggedCombo))) {
            $label = [string]$entry[1].SelectedItem
            if ($script:Choices.Contains($label)) {
                Set-Timeout $entry[0] ([int]$script:Choices[$label])
            }
        }
        Sync-UI
        $status.Text = 'Updated successfully.'
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Screen Timeout Tray', 'OK', 'Error') | Out-Null
    }
})

$refresh.Add_Click({ try { Sync-UI; $status.Text = 'Refreshed.' } catch { $status.Text = $_.Exception.Message } })
$menu.Add_Opening({ try { Sync-UI } catch { $status.Text = $_.Exception.Message } })
$openItem.Add_Click({ try { Sync-UI } catch {}; $window.Show(); $window.Activate() })
$windowsItem.Add_Click({ Start-Process 'ms-settings:powersleep' })
$notify.Add_DoubleClick({ try { Sync-UI } catch {}; $window.Show(); $window.Activate() })

$script:ReallyExit = $false
$window.Add_FormClosing({
    if (-not $script:ReallyExit) {
        $_.Cancel = $true
        $window.Hide()
    }
})
$exitItem.Add_Click({
    $script:ReallyExit = $true
    $notify.Visible = $false
    $window.Close()
    [System.Windows.Forms.Application]::Exit()
})

try { Sync-UI } catch {
    $status.Text = 'Unable to read current settings.'
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Screen Timeout Tray', 'OK', 'Error') | Out-Null
}
$window.Show()
[System.Windows.Forms.Application]::Run($window)
$notify.Visible = $false
$notify.Dispose()
$menu.Dispose()
$window.Dispose()
$icon.Dispose()
$bitmap.Dispose()
