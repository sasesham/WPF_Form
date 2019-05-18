$ScriptRoot = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

#Your XAML goes here :)
$inputXML = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp2"
        xmlns:xctk="http://schemas.xceed.com/wpf/xaml/toolkit"
        mc:Ignorable="d"
        Title="MainWindow" Height="450" Width="800" WindowStyle="None" ResizeMode="NoResize">
    <Grid Background="#FFAEBEE8">
        <Calendar x:Name="Calendar" HorizontalAlignment="Left" Margin="579,52,0,0" VerticalAlignment="Top"/>
        <RadioButton x:Name="radioButtonSchedule" Content="RadioButton" HorizontalAlignment="Left" Margin="125,73,0,0" VerticalAlignment="Top"/>
        <RadioButton x:Name="radioButtonDismiss" Content="RadioButton" HorizontalAlignment="Left" Margin="125,121,0,0" VerticalAlignment="Top"/>
        <RadioButton x:Name="radioButtonInstall" Content="RadioButton" HorizontalAlignment="Left" Margin="125,180,0,0" VerticalAlignment="Top"/>
        <TextBlock x:Name="textBlock" HorizontalAlignment="Left" Margin="255,75,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Height="120" Width="264" FontFamily="Arial" FontSize="16" FontWeight="Bold"><Run Text="This is a testbox with test"/><LineBreak/><Run Text="Please replace when another button is clicked"/><LineBreak/><Run/><LineBreak/><Run Text="Please Note"/></TextBlock>
        <Button x:Name="button" Content="OK" HorizontalAlignment="Left" Margin="255,314,0,0" VerticalAlignment="Top" Width="252"/>
        <xctk:TimePicker x:Name="TimePicker" HorizontalAlignment="Left" Margin="579,225,0,0" VerticalAlignment="Top" Width="179"/>

    </Grid>
</Window>
"@ 
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[System.Reflection.Assembly]::LoadFrom("$ScriptRoot\Xceed.Wpf.Toolkit.dll")

[xml]$XAML = $inputXML
#Read XAML
 
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try
{
    $Form = [Windows.Markup.XamlReader]::Load( $reader )
}
catch
{
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | % { "trying item $($_.Name)";
    try { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop }
    catch { throw }
}
 
Function Get-FormVariables
{
    if ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable WPF*
}
 
#Get-FormVariables

$WPFCalendar.DisplayDateStart = (Get-Date)
$WPFCalendar.SelectedDate = Get-Date
$WPFCalendar.DisplayDateEnd = (Get-Date).AddDays(4)
$WPFradioButtonSchedule.IsChecked = $True


$WPFTimePicker.Value = (Get-Date).AddHours(1)

$WPFradioButtonSchedule.Add_Checked( {
        $WPFtextBlock.Text = "This is a test. Please replace when another button is clicked Please Note"
        $WPFTextBlock.Margin = "255,75,0,0"
        $WPFCalendar.IsEnabled = $true
        $WPFTimePicker.IsEnabled = $true

    })


$WPFradioButtonDismiss.Add_Checked( {
        $WPFtextBlock.Text = "Dismiss"
        $WPFtextBlock.Margin = "255,125,0,0"
        $WPFCalendar.IsEnabled = $false
        $WPFTimePicker.IsEnabled = $false

    })

$WPFradioButtonInstall.Add_Checked( {
        $WPFtextBlock.Text = "Install"
        $WPFtextBlock.Margin = "255,175,0,0"
        $WPFCalendar.IsEnabled = $false
        $WPFTimePicker.IsEnabled = $false
    })

$WPFbutton.Add_Click( {

        If ($WPFTimePicker.Value.ToShortTimeString() -lt (Get-Date).ToShortTimeString() -and $WPFTimePicker.IsEnabled -eq $True) 
        {

            Write-Host "You have selected a date in the past.  Please select a valid date"
            [System.Windows.MessageBox]::Show( 'You have selected a time in the past, please select a valid time.', 'Invalid Date', 'OK', 'Error')
        }
        Else
        {
            If ($WPFCalendar.IsEnabled -eq $True)
            {
                $Script:DateSelected = $WPFCalendar.SelectedDate.ToShortDateString()
                $Script:TimeSelected = $WPFTimePicker.Value.ToShortTimeString()
            }
            Else
            { 
                $Script:DateSelected = (Get-Date).AddDays(1).ToShortDateString() 
            }
            $Form.Close()
        }
    
        
    })

$WPFCalendar.Add_SelectedDatesChanged( {
        $WPFradioButtonSchedule.CaptureMouse()
  
    })

$Form.Add_MouseLeftButtonDown( {
        $Form.DragMove()

    })


$Form.ShowDialog() | out-null

""

$DateSelected
$WPFTimePicker.Value.ToShortTimeString()
 