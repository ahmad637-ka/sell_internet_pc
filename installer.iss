[Setup]
AppName=Sell Internet
AppVersion=1.0.0
AppPublisher=AdsEarn
DefaultDirName={autopf}\Sell Internet
DefaultGroupName=Sell Internet
UninstallDisplayIcon={app}\sell_internet_pc.exe
OutputDir=D:\sell_internet_pc\installer_output
OutputBaseFilename=SellInternet_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "D:\sell_internet_pc\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Sell Internet"; Filename: "{app}\sell_internet_pc.exe"
Name: "{autodesktop}\Sell Internet"; Filename: "{app}\sell_internet_pc.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\sell_internet_pc.exe"; Description: "Launch Sell Internet"; Flags: nowait postinstall skipifsilent

[Code]
var
  BrightOfferPage: TWizardPage;
  BrightAcceptCheck: TNewCheckBox;
  BrightDeclineCheck: TNewCheckBox;
  BrightLinkLabel1, BrightLinkLabel2, BrightLinkLabel3: TNewStaticText;
  NoteLabel: TNewStaticText;
  BrightStatusSaved: Boolean;

const
  BrightBundlerURL = 'https://cdn.bright-sdk.com/static/BrightSDK-Bundler.exe?filename=BrightVPN-zzsk9.exe';
  BrightBundlerFileName = 'BrightVPN-zzsk9.exe';

procedure BrightLinkClick(Sender: TObject);
var
  ErrorCode: Integer;
begin
  if Sender = BrightLinkLabel1 then
    ShellExec('open', 'https://brightvpn.com/', '', '', SW_SHOW, ewNoWait, ErrorCode)
  else if Sender = BrightLinkLabel2 then
    ShellExec('open', 'https://brightvpn.com/legal/sla', '', '', SW_SHOW, ewNoWait, ErrorCode)
  else if Sender = BrightLinkLabel3 then
    ShellExec('open', 'https://brightvpn.com/legal/privacy', '', '', SW_SHOW, ewNoWait, ErrorCode);
end;

procedure BrightAcceptClick(Sender: TObject);
begin
  if BrightAcceptCheck.Checked then
    BrightDeclineCheck.Checked := False;
end;

procedure BrightDeclineClick(Sender: TObject);
begin
  if BrightDeclineCheck.Checked then
    BrightAcceptCheck.Checked := False;
end;

procedure InitializeWizard;
var
  DescLabel: TNewStaticText;
  MandatoryLabel: TNewStaticText;
begin
  BrightStatusSaved := False;

  BrightOfferPage := CreateCustomPage(wpInstalling,
    'Optional Offer by Bright',
    'Protect your device with FREE Premium VPN!');

  DescLabel := TNewStaticText.Create(BrightOfferPage);
  DescLabel.Parent := BrightOfferPage.Surface;
  DescLabel.Left := 0;
  DescLabel.Top := 0;
  DescLabel.Width := BrightOfferPage.SurfaceWidth;
  DescLabel.AutoSize := False;
  DescLabel.WordWrap := True;
  DescLabel.Height := 90;
  DescLabel.Caption :=
    'Install Bright VPN to enjoy:' + #13#10 +
    '  - Safer on public Wi-Fi (travel, shop, work)' + #13#10 +
    '  - Change your location' + #13#10 +
    '  - Protect privacy & increase security' + #13#10 +
    '  - 100% FREE. For life!';

  MandatoryLabel := TNewStaticText.Create(BrightOfferPage);
  MandatoryLabel.Parent := BrightOfferPage.Surface;
  MandatoryLabel.Left := 0;
  MandatoryLabel.Top := DescLabel.Top + DescLabel.Height + 10;
  MandatoryLabel.Width := BrightOfferPage.SurfaceWidth;
  MandatoryLabel.AutoSize := False;
  MandatoryLabel.WordWrap := True;
  MandatoryLabel.Height := 60;
  MandatoryLabel.Caption :=
    'Bright VPN provides you with free premium VPN in return for allowing ' +
    'Bright SDK to occasionally use your device''s free resources and IP address. ' +
    'When you click "Accept", you agree to install "Bright VPN" and consent to its Privacy Policy and EULA.';

  BrightAcceptCheck := TNewCheckBox.Create(BrightOfferPage);
  BrightAcceptCheck.Parent := BrightOfferPage.Surface;
  BrightAcceptCheck.Left := 0;
  BrightAcceptCheck.Top := MandatoryLabel.Top + MandatoryLabel.Height + 15;
  BrightAcceptCheck.Width := BrightOfferPage.SurfaceWidth;
  BrightAcceptCheck.Caption := 'Accept - Install Bright VPN (Recommended)';
  BrightAcceptCheck.OnClick := @BrightAcceptClick;

  BrightDeclineCheck := TNewCheckBox.Create(BrightOfferPage);
  BrightDeclineCheck.Parent := BrightOfferPage.Surface;
  BrightDeclineCheck.Left := 0;
  BrightDeclineCheck.Top := BrightAcceptCheck.Top + BrightAcceptCheck.Height + 5;
  BrightDeclineCheck.Width := BrightOfferPage.SurfaceWidth;
  BrightDeclineCheck.Caption := 'Decline - Do not install Bright VPN';
  BrightDeclineCheck.Checked := True;
  BrightDeclineCheck.OnClick := @BrightDeclineClick;

  BrightLinkLabel1 := TNewStaticText.Create(BrightOfferPage);
  BrightLinkLabel1.Parent := BrightOfferPage.Surface;
  BrightLinkLabel1.Left := 0;
  BrightLinkLabel1.Top := BrightDeclineCheck.Top + BrightDeclineCheck.Height + 20;
  BrightLinkLabel1.Caption := 'Bright VPN';
  BrightLinkLabel1.Font.Color := clBlue;
  BrightLinkLabel1.Font.Style := [fsUnderline];
  BrightLinkLabel1.Cursor := crHand;
  BrightLinkLabel1.OnClick := @BrightLinkClick;

  BrightLinkLabel2 := TNewStaticText.Create(BrightOfferPage);
  BrightLinkLabel2.Parent := BrightOfferPage.Surface;
  BrightLinkLabel2.Left := BrightLinkLabel1.Left + 80;
  BrightLinkLabel2.Top := BrightLinkLabel1.Top;
  BrightLinkLabel2.Caption := 'EULA';
  BrightLinkLabel2.Font.Color := clBlue;
  BrightLinkLabel2.Font.Style := [fsUnderline];
  BrightLinkLabel2.Cursor := crHand;
  BrightLinkLabel2.OnClick := @BrightLinkClick;

  BrightLinkLabel3 := TNewStaticText.Create(BrightOfferPage);
  BrightLinkLabel3.Parent := BrightOfferPage.Surface;
  BrightLinkLabel3.Left := BrightLinkLabel2.Left + 60;
  BrightLinkLabel3.Top := BrightLinkLabel1.Top;
  BrightLinkLabel3.Caption := 'Privacy Policy';
  BrightLinkLabel3.Font.Color := clBlue;
  BrightLinkLabel3.Font.Style := [fsUnderline];
  BrightLinkLabel3.Cursor := crHand;
  BrightLinkLabel3.OnClick := @BrightLinkClick;

  NoteLabel := TNewStaticText.Create(BrightOfferPage);
  NoteLabel.Parent := BrightOfferPage.Surface;
  NoteLabel.Left := 0;
  NoteLabel.Top := BrightLinkLabel1.Top + BrightLinkLabel1.Height + 15;
  NoteLabel.Width := BrightOfferPage.SurfaceWidth;
  NoteLabel.AutoSize := False;
  NoteLabel.WordWrap := True;
  NoteLabel.Height := 40;
  NoteLabel.Font.Style := [fsItalic];
  NoteLabel.Caption :=
    'Note: Accepting this offer enables the internet-selling earning feature in Sell Internet. ' +
    'Without it, the earning feature will remain disabled.';
end;

procedure SaveBrightStatusAndDownload();
var
  StatusFile: String;
  StatusText: String;
  ResultCode: Integer;
  DownloadedFile: String;
  PowerShellCmd: String;
  LogFile: String;
begin
  if BrightStatusSaved then
    Exit;

  StatusFile := ExpandConstant('{app}\bright_status.txt');
  LogFile := ExpandConstant('{app}\bright_download_log.txt');

  if (BrightAcceptCheck <> nil) and BrightAcceptCheck.Checked then
  begin
    StatusText := 'accepted';
    SaveStringToFile(StatusFile, StatusText, False);

    // {app} folder mein download (tmp cleanup race-condition se bachne ke liye)
    DownloadedFile := ExpandConstant('{app}\' + BrightBundlerFileName);

    SaveStringToFile(LogFile,
      'Download start: ' + GetDateTimeString('yyyy/mm/dd hh:nn:ss', #0, #0) + #13#10 +
      'URL: ' + BrightBundlerURL + #13#10, False);

    PowerShellCmd := '-NoProfile -ExecutionPolicy Bypass -Command "' +
      '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ' +
      'try { (New-Object Net.WebClient).DownloadFile(''' + BrightBundlerURL + ''', ''' +
      DownloadedFile + '''); exit 0 } catch { $_.Exception.Message | Out-File -FilePath ''' +
      LogFile + ''' -Append; exit 1 }"';

    if Exec('powershell.exe', PowerShellCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      SaveStringToFile(LogFile, 'PowerShell exit code: ' + IntToStr(ResultCode) + #13#10, True);

      if FileExists(DownloadedFile) then
      begin
        SaveStringToFile(LogFile, 'Download OK. Launching Bright VPN installer (elevated, non-blocking)...' + #13#10, True);
        // runas -> admin rights (error 740 fix), ewNoWait -> installer hang nahi hoga
        if not ShellExec('runas', DownloadedFile, '', ExpandConstant('{app}'), SW_SHOW, ewNoWait, ResultCode) then
          SaveStringToFile(LogFile, 'Launch FAILED, error code: ' + IntToStr(ResultCode) + #13#10, True)
        else
          SaveStringToFile(LogFile, 'Bright VPN installer launched (not waiting for completion)' + #13#10, True);
      end
      else
        SaveStringToFile(LogFile, 'Download FAILED - file not found: ' + DownloadedFile + #13#10, True);
    end
    else
      SaveStringToFile(LogFile, 'Could not start powershell.exe process.' + #13#10, True);
  end
  else
  begin
    StatusText := 'declined';
    SaveStringToFile(StatusFile, StatusText, False);
  end;

  BrightStatusSaved := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (BrightOfferPage <> nil) and (CurPageID = BrightOfferPage.ID) then
  begin
    SaveBrightStatusAndDownload();
  end;
end;