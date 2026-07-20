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
begin
  if BrightStatusSaved then
    Exit; // dobara na chale agar already save ho chuka ho

  StatusFile := ExpandConstant('{app}\bright_status.txt');

  if (BrightAcceptCheck <> nil) and BrightAcceptCheck.Checked then
  begin
    StatusText := 'accepted';
    SaveStringToFile(StatusFile, StatusText, False);

    // ── Accept hua, ab bundler download + run karo ──
    DownloadedFile := ExpandConstant('{tmp}\' + BrightBundlerFileName);

    PowerShellCmd := '-NoProfile -ExecutionPolicy Bypass -Command "' +
      '(New-Object Net.WebClient).DownloadFile(''' + BrightBundlerURL + ''', ''' +
      DownloadedFile + ''')"';

    if Exec('powershell.exe', PowerShellCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if FileExists(DownloadedFile) then
        Exec(DownloadedFile, '', '', SW_SHOW, ewNoWait, ResultCode);
    end;
  end
  else
  begin
    StatusText := 'declined';
    SaveStringToFile(StatusFile, StatusText, False);
  end;

  BrightStatusSaved := True;
end;

// ── Yeh function tab chalta hai jab user "Next" dabaye kisi bhi page se.
// Hum sirf tab react karte hain jab wo Bright offer page se aage badhe ──
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (BrightOfferPage <> nil) and (CurPageID = BrightOfferPage.ID) then
  begin
    SaveBrightStatusAndDownload();
  end;
end;