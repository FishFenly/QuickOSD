#TITLE - 		QuickOSD 1.6
#AUTHOR - 		Joseph Fenly
#DESCRIPTION - 	Prebuild checker
#CHANGELOG - 	1.0: Initial commit - Basic XAML generation, Form Variables function and Ethernet function
#				1.1: Added CMTrace and CMD buttons in XAML
#				1.2: Changed status indicators to verbose logging panel
#				1.3: Added Power Status checking
#				1.4: Added Button functionality and added further logging to panel from status checks
#				1.5: Finshed functionality + Changed WindowStyle to None to remove close button + Removed debug functions
#				1.6: Add build logging functionality
#				1.7: Fixed issue with cmd + cmtrace not showing infront of app
#				1.8: Model Validation
#PLCHANGES -	Check for existing computer objects with matching name
#				Change ComputerName input to a device information displaying PC name, MAC, IP
#				Validate domain credentials with an attempt to map a dummy drive or something
#				Automate model validation, maybe a lookup on added driver packs?
#region XAML
$ixaml = @"
<Window x:Class="QuickOSD.UserInterface"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:QuickOSD"
        mc:Ignorable="d"
                Title="QuickOSD" Height="550" Width="750" Background="#FFF9F9F9" 
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize" WindowStyle="None">
    <Grid>
        <Border BorderBrush="#FFF9F9F9" BorderThickness="2" Margin="357,51,26,0" Background="#FF383636" Height="443" VerticalAlignment="Top" CornerRadius="9">
            <StackPanel Margin="8" >
                <Label x:Name="statusIndicatorTitle" Height="27" Content="Status Indicator" Foreground="#FFF9F9F9" BorderThickness="0,0,0,2" BorderBrush="#FFF9F9F9"/>
				<RichTextBox x:Name="statusTextBox" Margin="0,5,0,0" Height="340" Width="331" Background="#FF383636" Foreground="#FFF9F9F9" IsReadOnly="True">
					<FlowDocument>
						<Paragraph>
							<Run Text=""/>
						</Paragraph>
					</FlowDocument>
				</RichTextBox>
				<Border BorderBrush="#FFF9F9F9" BorderThickness="2" Background="#FF383636" CornerRadius="9" Height="26" VerticalAlignment="Top" Margin="120,15,120,0" Width="90">
					<Button x:Name="retryButton" Content="Retry" Margin="0,0,8,0" BorderThickness="0" Background="#FF383636" Foreground="#FFF9F7F7" HorizontalAlignment="Right" Width="72"/>
				</Border>
            </StackPanel>
        </Border>
        <StackPanel HorizontalAlignment="Left" Height="322" Margin="29,51,0,0" VerticalAlignment="Top" Width="247">
            <Label x:Name="deviceInfo" Content="Device Information" BorderThickness="0,0,0,2" BorderBrush="#FF383636" Margin="0,0,10,0"/>
            <Label x:Name="userName" Content="Built By" Margin="0,18,0,0"/>
            <StackPanel Orientation="Horizontal">
                <Border BorderBrush="#FFF9F9F9" BorderThickness="2" Background="#FF383636" CornerRadius="9" HorizontalAlignment="Right" Width="235" Margin="7,0,0,0" Height="31">
                    <TextBox x:Name="userNameInput" TextWrapping="Wrap" Text="" ToolTip="Please enter your first and last names." Background="#FF383636" Width="215" Margin="0,3,8,0" Foreground="#FFF9F9F9" BorderThickness="0"  HorizontalAlignment="Right" Height="20" VerticalAlignment="Top"/>
                </Border>
            </StackPanel>
            <Label x:Name="computerName" Content="Computer Name" Margin="0,10,0,0"/>
            <StackPanel Orientation="Horizontal">
                <Border BorderBrush="#FFF9F9F9" BorderThickness="2" Background="#FF383636" CornerRadius="9" HorizontalAlignment="Right" Width="235" Margin="7,0,0,0" Height="30">
                    <TextBox x:Name="computerNameInput" Height="20" TextWrapping="Wrap" Text="" ToolTip="Laptops: dur-lp-xxx, Desktops: dur-ws-xxx, Surfaces: dur-surface-xxx" Background="#FF383636" HorizontalAlignment="Right" Width="215" Margin="0,3,8,3" Foreground="#FFF9F9F9" BorderThickness="0"/>
                </Border>
            </StackPanel>
            <Border BorderBrush="#FFF9F9F9" BorderThickness="2" Background="#FF383636" CornerRadius="9" Margin="45,40,45,0" Height="26">
                <Button x:Name="tsContinueButton" Content="Continue" Background="#FF383636" Foreground="#FFF9F7F7" Margin="8,0,8,0" BorderThickness="0" IsEnabled="False"/>
            </Border>
        </StackPanel>
        <Border BorderBrush="#FFF9F9F9" BorderThickness="2" Background="#FF383636" CornerRadius="9" Margin="32,371,0,0" Height="26" HorizontalAlignment="Left" Width="94" VerticalAlignment="Top">
            <Button x:Name="cmtraceButton" Content="CmTrace" Margin="8,0,8,0" BorderThickness="0" Background="#FF383636" Foreground="#FFF9F7F7" HorizontalAlignment="Right" Width="75" Height="20" VerticalAlignment="Bottom" />
        </Border>
        <Border BorderBrush="#FFF9F9F9" BorderThickness="2" Background="#FF383636" CornerRadius="9" Margin="185,371,0,0" HorizontalAlignment="Left" Width="94" Height="26" VerticalAlignment="Top">
            <Button x:Name="f8Button" Content="CMD" Margin="8,0,8,0" BorderThickness="0" Background="#FF383636" Foreground="#FFF9F7F7" HorizontalAlignment="Right" Width="75" />
        </Border>
    </Grid>
</Window>
"@
$ixaml = $ixaml -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
#endregion
#region Read XAML
[xml]$xaml = $ixaml
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try{
    $form=[Windows.Markup.XamlReader]::Load($reader)
}
catch{
    return $Error[0]
    exit
}
$xaml.SelectNodes("//*[@Name]") | % {
    Set-Variable -Name "WPF$($_.Name)" -Value $form.FindName($_.Name)
}
#endregion
#region Data
#Network
function Get-EthernetIP{
	try{
		$ip = Get-NetIPConfiguration | ? InterfaceAlias -Like "*Ethernet*" | 
			select -Expand IPv4Address | select -Expand IPaddress -First 1
		return "IP address is: " + $ip
	}
	catch{
		return "An unexpected error occured while trying to evaluate your IP address"
	}
}
function Get-EthStatus{
	Get-WmiObject Win32_NetworkAdapter | 
		? NetConnectionID -like "*Ethernet*" | select -expand NetConnectionStatus
}
#Suppoerted Models
function Get-Model{
	Get-WmiObject Win32_computersystem | select -expand model
}
$Models = "HP Elitebook 840 G1","HP Elitebook 840 G2","HP Elitebook 8460p","HP Elitebook 8470p","Surface Book","Surface Pro 3","Surface Pro 4"
#Site Connection
#function Ping-SCCM{
#	try{
#		Test-Connection "siteserver" -ea Stop
#	}
#	catch{
#	
#	}
#}
#Power
function Get-DeviceType{
	$ChassisType = Get-WmiObject Win32_SystemEnclosure | select -Expand ChassisTypes
	return $ChassisType
}
function Get-BatteryStatus{
	$Battery = Get-WmiObject -Namespace "root\wmi" -class BatteryStatus | ? voltage -ne 0 | select -expand PowerOnline
	return $Battery
}
#endregion
#region Logic
$UCreds = Get-Credential -Message "Please enter your domain credentials eg. Waterstons\username"
function Run-StatusChecks{
	$WPFstatusTextBox.Appendtext("Starting network checks" + [char]13) 
	if((Get-EthStatus).ToString() -eq "2") {
		$WPFstatusTextBox.Appendtext("Completing network status check" + [char]13)
		$WPFstatusTextBox.Appendtext("Getting IP address assigned to Ethernet adapter" + [char]13)
		$WPFstatusTextBox.Appendtext((Get-EthernetIP).ToString() + [char]13)
		#$WPFstatusTextBox.Appendtext("Establishing connection to SCCM Site"  + [char]13)
		$LANOK = "pass"
	}
	else{
		$WPFstatusTextBox.Appendtext("Error: No network connection found" + [char]13)
		$LANOK = "fail"
	}
	if($LANOK -eq "pass"){
		$WPFstatusTextBox.Appendtext("Querying device type" + [char]13)
		if((Get-DeviceType).ToString() -eq "10" -or (Get-DeviceType).ToString() -eq "9" -or (Get-DeviceType).ToString() -eq "14"){
			$WPFstatusTextBox.Appendtext("The device is a Laptop" + [char]13)
			if((Get-BatteryStatus).ToString() -eq "True"){
				$WPFstatusTextBox.Appendtext("The device is connected to a power source" + [char]13)
				$PowerOK = "pass"
			}
			else{
				$WPFstatusTextBox.Appendtext("Please connect your device to a power source" + [char]13)
				$PowerOK = "fail"
			}
		}
		else{
			$WPFstatusTextBox.Appendtext("The device is a Desktop or VM" + [char]13)
			$PowerOK = "pass"
		}
		$WPFstatusTextBox.Appendtext("Checking if model is supported" + [char]13)
		if($Models -contains (Get-Model).ToString()) {$smodel = "pass"} else {$smodel = "fail"}
	}
	else{
		$WPFstatusTextBox.Appendtext([char]13 + "Preflight checks failed. Please resolve the above issues and reboot" + [char]13)
	}
	if($LANOK -and $PowerOK -and $smodel -eq "pass"){
		$WPFtsContinueButton.IsEnabled = "True"
	}
}
Run-StatusChecks
#endregion
#region Buttons
$WPFtsContinueButton.Add_Click({
	$WPFstatusTextBox.Appendtext("Checking input fields" + [char]13)
	if($WPFuserNameInput.Text -and $WPFcomputerNameInput.Text -ne ""){
		$WPFstatusTextBox.Appendtext("Creating build log" + [char]13)
		New-Item "x:\temp" -ItemType Directory
		$BLog = New-Item "x:\temp\BuildLog_$(Get-date -f dd-MM-yy_hh-mm).log"
		"Built By: " + $WPFuserNameInput.Text | Out-File $BLog -Append
		"ComputerName: " + $WPFcomputerNameInput.Text | Out-File $BLog -Append
		New-PSDrive -Name "M" -PSProvider FileSystem -Root "\\fileshare\BuildLogs" -Credential $UCreds
		Copy-Item -Path $Blog -Destination M:\
		Remove-PSDrive -Name "M"
		$WPFstatusTextBox.Appendtext("Build preflight checks passed. Closing this window.")
		[Environment]::Exit(1)
	}
	else{
		$WPFstatusTextBox.Appendtext("You have not entered your name and Computer Name" + [char]13)
	}
})
$WPFf8Button.Add_Click({
	try{
		$WPFstatusTextBox.Appendtext("Opening a CommandLine terminal." + [char]13)
		Start-Process "X:\Windows\system32\cmd.exe" -EA SilentlyContinue
	}
	catch{
		$WPFstatusTextBox.Appendtext("Could not open a CommandLine terminal." + [char]13)
	}
})
$WPFcmtraceButton.Add_Click({
	try{
		$WPFstatusTextBox.Appendtext("Opening CmTrace." + [char]13)
		Start-Process "X:\sms\bin\x64\CMTrace.exe" -EA SilentlyContinue
	}
	catch{
		$WPFstatusTextBox.Appendtext("Could not open the CMTrace tool." + [char]13)
	}
})
$WPFretryButton.Add_Click({
	$WPFstatusTextBox.Document.Blocks.Clear()
	Run-StatusChecks
})
#endregion
#Load form
[void]$form.ShowDialog()