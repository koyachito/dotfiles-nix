# Fedora Sway Spin 44 + Nix + standalone Home Manager

この手順は実機でPhaseごとに停止して確認する。Ubuntuの作業環境では
Fedoraの起動、IME、物理キー、SELinuxの実動作は確認できない。
2026-10-16の作成環境では、linux-base/fedora-base/fedoraのactivationPackageの
derivation評価、生成設定の確認、ShellCheck、Bash構文、YAML/INI/lockの構文確認が通った。
全アプリのbuild・Home Manager switch・Fedora実機への適用は実施していない。
下のコマンドをまとめて実行しない。各Phaseの確認が通ってから次へ進む。
リポジトリ内の旧Arch installer、extra.sh、firewall.sh、sddm-theme.shは使わない。

Fedora 44を対象とする。`dnf install`は既にあるRPMを重複インストールしないため、
bootstrapを再実行できる（利用可能な更新・依存関係の変更はdnfのtransactionで確認する）。
Sway本体・NetworkManager・display managerの再設定は行わない。
Nixはdnfとは独立したパッケージ管理なので、既存のdnf版ユーザーアプリを検出して
自動スキップしない。Nix管理したいアプリはHMのprofileから起動する。
移行完了後、重複するFedora版の削除はdnfの依存関係を確認して別途判断する。
`command -v`による一律スキップは再現性を失うため採用しない。

将来のディストリビューション移行を考え、ユーザーアプリ群は全てNixで管理する。
`nix/home.nix`と`nix/packages.nix`はLinux共通、`nix/fedora.nix`と`fedora/bootstrap.sh`
だけをFedora固有層とする。別ディストリビューションではまず`linux-base`を使える。
これはSway設定やxremapの自動起動を切り替えないユーザー環境用プロファイル。
完全なデスクトップ移植時には、新OSのSway/IME/udev/セッション連携を担当する
小さなhost moduleを追加する。dnfが他のディストリビューションで実行されることはない。
Fcitx5本体・Mozcは当初のOS統合方針に従いFedora管理のままとする。
これも将来Nixへ移す場合には、ホストGTK/Qtアプリとのmodule整合を別途検証する。
Nix製Qt6アプリ（現在はKDE Connect）には`nix/qt-app.nix`で同じNixpkgsの
Fcitx Qt frontendを付ける。FedoraのQt pluginと混ぜないよう、QT_PLUGIN_PATHは
そのアプリのwrapper内だけで設定する。Nix製Qt6アプリを追加するときもこのhelperを使う。

## 責務と既存設定の扱い

| Fedora / dnf | Nix / Home Manager |
|---|---|
| Sway、swaybg、swayidle、swaylock、XWayland | Waybar、Mako、Kitty、Fuzzel、wlsunset |
| Fcitx5本体・Mozc・GTK/Qtモジュール | Fcitxの初期設定例（本体は入れない） |
| locale、PipeWire、WirePlumber | 日本語/ユーザーフォント・CLI・GUIアプリ |
| portal、logind、udev、uinput、input group、SELinux | xremap実行ファイル・user service・設定 |
| firmware、boot、NetworkManager、display manager | Neovim、Yazi、Bash、補助scripts |

既存のKitty、Waybar、Mako、Neovim、Yazi、Pandoc、Zathura設定をsourceとして
`xdg.configFile`へ移す。手動の`ln -sfn`と違い、既存ファイルの衝突を検出でき、
Nix storeに取り込んだ世代へ切り戻せる。リポジトリを移動してもリンクは壊れない。
`~/.config/systemd`全体の置換はやめ、xremapのunitのみHMが生成する。
`config/systemd/user/xremap.service`は調査済みだが旧Arch installer用として残す。
FedoraではそのCargoパス/default.targetのunitをコピーせず、`nix/home.nix`の
絶対パスとgraphical-session.targetに連動するunitを使う。
Fcitxのprofile/configは実行中に書き戻されるので、初回のみ書き込み可能な通常ファイルを
生成する。既存ファイルは上書きしない。変更したい場合はGUIまたはこの手順で明示的に更新する。

`othersettings/.bashrc`の固定パス`/home/koyachito/.local/bin`は引き継がず、
HMのsessionPathでユーザーごとに設定する。既存のalias、prompt、EDITOR、zoxideを維持する。
`.profile`のCargo PATHもsessionPathに統合する。Fedoraのシェルは変更しない。

## Phase 1 — 最低限のSway操作

**現状確認**: TTY（Ctrl+Alt+F3など）も使える状態にしてから実行する。

```bash
cat /etc/os-release
printf '%s\n' "$XDG_CURRENT_DESKTOP" "$WAYLAND_DISPLAY" "$SWAYSOCK"
command -v sway foot kitty fuzzel wmenu
swaymsg -t get_version
```

既存dotfilesの操作は以下。ModはSuper/Windowsキー。変換キーはPhase 4までSuperにならない。

| 操作 | キー |
|---|---|
| terminal / launcher | Super+Enter / Super+d |
| close | Super+q |
| focus | Super+h/j/k/l または矢印 |
| move | Super+Shift+h/j/k/l または矢印 |
| workspace / send to workspace | Super+1〜0 / Super+Shift+1〜0 |
| floating / fullscreen | Super+Shift+Space / Super+f |
| resize | Super+r → h/j/k/l、EnterかEscで終了 |
| reload / logout | Super+Shift+c / Super+Shift+e（即終了） |

**変更内容**: Phase 1ではリポジトリのSway全体をコピーしない。
既存設定にKitty/Fuzzelがある一方で実行ファイルがない場合、Fedora Spinにある
foot/wmenu等の実在するコマンドを一時的に使う。

**実行**: `~/.config/sway/config`があれば、通常ファイルかsymlinkかを`ls -l`で確認し、
`cp -a`で日時付きのバックアップを取る。Fedoraの`/etc/sway/config`も確認する。
設定全体のコピーが必要なら`cp -L`で通常ファイルとしてコピーし、
`diff -u /etc/sway/config ~/.config/sway/config`を見てから編集する。
既存の`$term`/`$menu`を確認済みのコマンドに直し、他の設定は触らない。

```bash
sway --validate --config ~/.config/sway/config
swaymsg reload
```

**動作確認**: 上の全操作を実際に試す。Fedora初期設定ではclose/reload等の
キーが異なる場合があるので、現在の設定のbindsymも読む。アプリ起動不能ならTTYへ戻し、
バックアップに戻す。この段階でセッションのlogoutは最後に試す。

## Phase 2 — Fcitx5 + Mozc単体

**現状確認**:

```bash
locale
locale -a
rpm -q fcitx5 fcitx5-mozc fcitx5-gtk fcitx5-qt
pgrep -a -f 'fcitx5|ibus-daemon'
cat ~/.config/sway/environment /etc/sway/environment 2>/dev/null
```

**変更内容・実行**:

```bash
bash fedora/bootstrap.sh ime
```

`ja_JP.utf8`がlocale一覧にあることを確認する。英語UIを維持しても日本語入力はできる。
フォントはNixで管理する。初期復旧時に`fc-match :lang=ja`で日本語フォントが無ければ、
このPhaseの確認用に限りFedora 44の`google-noto-sans-cjk-fonts`を一時導入できる。
日本語UIも希望する場合のみ`sudo localectl set-locale LANG=ja_JP.UTF-8`を実行する。
キーボード配列は勝手に変更しない。JISならSwayの`xkb_layout jp`、USなら`us`を
既存設定との差分を見て設定し、Fcitxのグループ配列も同じにする。

`fedora/ime-environment.conf`を読み、既存のenvironment.dファイルとの差分を確認してから
`~/.config/environment.d/60-dotfiles-ime.conf`へコピーする。
FedoraのSwayラッパーがenvironment.dを読み込むことを、`rpm -ql sway-config-fedora`
で見つけた起動スクリプトで確認する。ログアウト・ログイン後、Swayから起動したterminalで
`printenv XMODIFIERS QT_IM_MODULE GTK_IM_MODULE`を確認する。
期待値は`@im=fcitx`、`fcitx`、GTKは未設定。
GTKのWayland入力はtext-input-v3、Qtはfcitxモジュール、XWaylandはXIMを使用する。
XWayland GTKだけに必要なら`GTK_IM_MODULE=fcitx アプリ名`と個別指定する。

Swayの既存`exec_always ... fcitx5`を`exec fcitx5 -d`に変更する。
reloadごとのIME再起動を防ぐ。Fedoraのfcitx5-autostart等で既に起動している場合は
起動元を1つに揃え、IBusが実際に起動していればそのuser autostartを無効にする。
他のデスクトップ向けシステムサービスを一括で無効化しない。
現在のセッションでは`fcitx5 -d`で起動する（まだ起動していない場合のみ）。

`fcitx5-configtool`でKeyboard (Japanese)とMozcを登録する。
このPhaseは既定のCtrl+Spaceで切り替える。まだCaps設定やxremapを適用しない。

**動作確認**: terminal（foot/Kitty）、FirefoxのWaylandウィンドウ、Qtアプリで
`nihongo`→「日本語」と変換・確定できること、候補表示位置、直接入力への復帰を確認する。
`fcitx5-remote -n`で`mozc`を確認する。問題があれば`fcitx5-diagnose`を保存して調べる。
QtのNixアプリについてはPhase 7で再度確認する。

## Phase 3 — CapsLock専用IME切替

**現状確認**: xremapの起動元・旧unitを確認し、動いていれば停止する。
`swaymsg -t get_inputs`でcaps:ctrl_modifier等がないか確認する。

**設計**: `Caps → Menu`をSway/XKBの`caps:menu`で行い、FcitxのTriggerKeysをMenuにする。
XKBでLockを持つCaps_Lockを生成しないため、大文字固定やLEDの切替を起こさない。
Swayのbindsymから`fcitx5-remote -t`を呼ぶ案は、リピートとキーの消費を別途扱う必要がある。
xremapでCaps→別キーにする案はuinput権限・デーモンに依存し、Phase順とも合わない。
そのため標準XKBオプションを選んだ。**物理MenuキーもIME切替になる**。
CapsのEsc/Ctrl機能は廃止し、単押しも長押しもIMEキーとする。
Fcitxが停止中は通常のMenuキーとしてアプリへ届くため、Fcitxの稼働確認が必要。

**変更内容・実行**: Fcitx設定を保存して終了する。
現在の`~/.config/fcitx5/config`と`config/fcitx5/config`の差分を読む。
GUIでToggle Input MethodにMenuを登録し、AltTriggerKeysのShift、グループ切替の
Super+Space/Super+Shift+Spaceを外す（既存のFirefox/floating操作との競合防止）。
またはバックアップ後にテンプレートをコピーする。profileはPhase 2で作成済みなら維持する。
Swayのkeyboardブロックへ`xkb_options caps:menu`を追加する。
既存の他のXKBオプションがあれば、競合するcaps設定のみ外してカンマ区切りで維持する。
`sway --validate`後にreloadし、Fcitxを起動し直す。

**動作確認**: Capsを10回押し、毎回ON/OFFが切り替わること、長押しで連続トグルしないこと、
Shift併用や直接入力時にも大文字固定が残らないことを確認する。
修飾キーとの同時押しは通常のホットキーと同様に別扱い。
Ctrl+Spaceを復旧用に残す。GTK/Qt/terminalそれぞれで確認してから次へ進む。

## Phase 4 — xremapと変換キー

**現状確認**:

```bash
id
ls -lZ /dev/uinput /dev/input/event*
getenforce
```

`libinput debug-events`等で物理変換キーがKEY_HENKANを送ることを確認する。
既存xremapはCapsのheld/aloneを削除、KEY_HENKAN→KEY_LEFTMETAを維持する。
RightAlt無効化も既存どおり。不要なら後で別変更として戻す。

**変更内容・実行**:

```bash
bash fedora/bootstrap.sh input
```

ログアウト・ログイン後に`id -nG`にinputがあり、`test -r /dev/input/eventX`と
`test -w /dev/uinput`が成功することを確認する。input groupは全入力イベントを読める権限。
rootのxremapや0666は使わない。SELinuxはEnforcingのままにする。
権限拒否は`sudo ausearch -m AVC,USER_AVC -ts recent`と`ls -lZ`で調べ、
まず既定ラベルを`restorecon`で戻す。`setenforce 0`や無差別なaudit2allowは実行しない。

指定順序ではNix導入がPhase 5なので、ここでは一時的なxremapが必要になる。
既存の実行ファイルがあれば利用する。なければupstreamの固定バージョンを確認し、
Fedora側で一時的にRust/Cargoを導入し、例として次を実行する。

```bash
sudo dnf install cargo gcc
cargo install --locked --version 0.15.7 xremap
~/.cargo/bin/xremap --watch "$PWD/config/xremap/config.yml"
```

全体modmapのみなのでcompositor featureは不要。まだサービス化しない。
**動作確認**: 変換+Enter、変換+h、変換+数字を試す。KEY_LEFTMETAの押下・解放を確認する。
Capsの切替も再確認。Ctrl+Cで一時xremapを終了する。
キー解放が異常なら物理キーを放し、TTYからプロセスを停止する。

## Phase 5 — SELinuxを維持したNix導入

**現状確認**: `getenforce`、`command -v nix`、空き容量、既存`/etc/nix/nix.conf`を確認。
既存Nixがあれば再インストールしない。

**変更内容・実行**: SELinux対応を持つDeterminate Nix Installerを利用する。
ディストリビューションとupstream Nixの違いもリンク先で確認する。
スクリプトをダウンロードして読み、installerのplanをレビューしてから対話実行する。

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix -o /tmp/install-nix.sh
less /tmp/install-nix.sh
sh /tmp/install-nix.sh install
```

実際に使用したinstallerバージョンを控える。承認前にSELinux関連の計画も読む。
**動作確認**: 新しいlogin shellで`nix --version`、`nix store ping`、`getenforce`、
`systemctl status nix-daemon.socket`を確認。EnforcingのままでNixが利用できること。

## Phase 6 — standalone Home Manager（デスクトップ切替前）

**現状確認**: `flake.nix`のusername/homeDirectory/systemをFedora実機に合わせる。
ホーム名をこの作業環境のユーザー名から自動推測しない。
Git clone先は任意。新しい移管先にpushするのは利用者が行う。

移管先のリポジトリは`git@github.com:koyachito/dotfiles-nix.git`。
公開後の実機では`git clone git@github.com:koyachito/dotfiles-nix.git ~/dotfiles-nix`
で取得する（この移行作業ではpushしない）。

**変更内容**: `fedora-base`はSway設定とxremapサービスをまだ切り替えない。
他のユーザー設定の衝突は予め確認する。

```bash
git diff
nix build 'path:.#homeConfigurations.fedora-base.activationPackage' --no-link
```

初回の`flake.lock`がない場合は`nix flake lock path:.`で生成し、Git管理する。
依存更新は明示的な作業にする。

**実行**: `nix run github:nix-community/home-manager/release-26.05 -- switch --flake path:.#fedora-base`
（最初のHome Manager CLI取得のみbranch指定。以後はlockされた設定を`home-manager`で使う。）
既存ファイル衝突はここで止まる。`--force`で上書きせず、対象ファイルを
`diff`/`readlink`で確認して日時付きバックアップに移す。
既存のdirectory symlinkは`cp -aL`で中身も保存してから移す。
同じバックアップ名を繰り返し使わない。

**動作確認**: `home-manager generations`、`command -v nvim kitty waybar`、
`bash -lic 'command -v zoxide; echo "$EDITOR"'`を確認する。
まだSway設定を切り替えない。

## Phase 7 — desktop設定とサービスの移管

**現状確認**: Fedoraの設定断片とsystemd連携を調べる。

```bash
rpm -ql sway-config-fedora sway-systemd
systemctl --user cat graphical-session.target sway-session.target
systemctl --user cat waybar.service mako.service xremap.service
ls -l ~/.config/sway ~/.config/systemd/user
diff -u ~/.config/sway/config config/sway/config
```

Fedora公式start-swayはenvironment.dを読み込む。HM版では既存のincludeを
Fedora公式の`/usr/libexec/sway/layered-include`方式に置換し、`/usr/share`、`/etc`、
ユーザーの順で同名ファイルを上書きする。実機にこのhelperがあることを確認する。
90-bar/90-swayidleと音量・明るさ・スクリーンショットの重複断片だけを空にし、
session/portal/polkit等はFedoraの設定を取り込む。さらに物理機の追加断片も確認する。
旧Arch壁紙パスはFedoraでは存在を保証できないため、HM版のみ単色背景へ変更する。
Fcitx5のXDG autostartはHiddenで抑え、Swayのexecへ統一する。
swayidleの停止と再起動も1つのexec_alwaysにまとめ、reloadで停止だけが走る問題を修正した。
Waybar/Makoはこの構成では既存Swayのexecが起動するため、Fedora側unit/autostartとの
二重起動を避ける。サービスを削除せず、現在の起動元を確認して片方に統一する。

**変更内容・実行**: 旧`~/.config/systemd`のdirectory symlinkを中身ごとバックアップし、
通常のuser unitディレクトリに移行する。旧xremapのdefault.target.wantsも退避し、
他の手作業のunitは維持する。xremapは停止してから切り替える。
`home-manager build --flake path:.#fedora`で生成を確認した後、
`home-manager switch --flake path:.#fedora`を実行する。
HMで生成したxremap unitのExecStartはNix storeの絶対パスになり、Cargo PATHに依存しない。
一時導入したCargo xremapは`cargo uninstall xremap`で外せる。
Rust自体はユーザー開発用にNix側にも含む。

HMの非NixOS GPU統合で出力されるsetupコマンドを確認し、Intel/AMDではそれを実行する。
NVIDIA proprietaryはFedoraカーネルドライバと一致するversion/hashをHMに指定してから
適用する。FedoraのGPUドライバをNixで置き換えない。
Kitty/Firefox等がGPU初期化で失敗しないことを確認する。

`.config/environment.d/60-dotfiles.conf`にはNix PATH、XDG_DATA_DIRS、IME変数を配置する。
Phase 2の`60-dotfiles-ime.conf`と内容が重なる場合は後者をバックアップへ退避する。
Fedoraのsession wrapperが読み込むことを確認し、再ログインする。
`.profile`だけにIME変数を置かない。systemd user managerとSwayでPATHが一致するか確認する。

**移植範囲**: install-commonのユーザーアプリを`nix/packages.nix`に整理した。
Archのkernel/base/intel-ucode/pacman-contrib/boot更新、SDDM・NetworkManager設定、
UFW導入は除外。PipeWire/portal/brightnessctl/libinput/UPowerはFedoraのものを使う。
不足時のみ対応するFedoraパッケージを調べて追加する。
ZellijはCargoからNixへ移管。Pandoc設定のTypst、Waybarクリック先のpavucontrolも追加。
Tesseractはeng/jpnを明示指定。`tesseract --list-langs`で確認する。
NeovimのLazy plugin管理とlazy-lock.jsonは維持し、初回起動にはネットワークが必要。
Lazyの書き込み先lockfileはstateへ移し、初回にリポジトリのlockをコピーする。
plugin更新をGit管理する場合はstateのlazy-lock.jsonをリポジトリへ戻して差分を確認する。
42headerの氏名/メール、wlsunsetのメキシコの座標は既存値を維持しているので必要なら編集する。
Hyprland専用設定・powermenu-hyprは移植しない。battery-warningは手動実行可能にし、
元の起動スケジュールが無いため新しい自動タイマーは作らない。

## Phase 8 — 再ログイン・再起動の確認

**現状確認**: まず再ログイン、次に再起動して、下記を記録する。
この表は実機で確認するまで未確認のままにする。

| 項目 | 確認 | 実機結果 |
|---|---|---|
| Sway | get_version、全主要bind、portalでファイル選択 | 未確認 |
| Fcitx5 | pgrepで単一起動、diagnose、IME変数 | 未確認 |
| Mozc | terminal/Firefox/Qtで変換・候補・確定 | 未確認 |
| Caps | ON/OFF、長押し、Lock固定がない | 未確認 |
| xremap | user unit active、変換+Enter/数字、キー解放 | 未確認 |
| SELinux | Enforcing、関連AVCなし、uinputアクセス可能 | 未確認 |
| Waybar/Mako | 単一起動、tray/clock/音量、notify-send | 未確認 |
| Kitty/shell | GPU、フォント、日本語、Nix PATH、zoxide | 未確認 |
| Neovim/Yazi | plugin、PDF open、kde-send | 未確認 |
| セッション終了 | graphical-session.targetとxremap停止 | 未確認 |

```bash
swaymsg -t get_version
systemctl --user status graphical-session.target xremap.service
journalctl --user -b -u xremap.service --no-pager
pgrep -a -x fcitx5
pgrep -a -x waybar
pgrep -a -x mako
systemctl --user show-environment
fcitx5-remote -n
notify-send 'Fedora migration' 'notification test'
getenforce
sudo ausearch -m AVC,USER_AVC -ts boot
```

AVCが無い場合のausearchの終了コードはエラー原因ではない。
**復旧**: TTYから`systemctl --user stop xremap`。Sway設定は保存した実ファイルへ戻す。
HMは`home-manager generations`に表示された前世代の`activate`を実行する。
Fedoraのudev/input group・locale変更はHM rollback対象外。
inputを外すなら`sudo gpasswd -d "$USER" input`後に再ログインする。
新規ルールだけを退避してudevをreloadする。既存のルールを一括削除しない。

## 再インストール時

Phase 1〜8の実機検証が完了した構成なら、通常は次の流れで復元できる。
Fedora Sway Spin → SELinux対応Nix導入 → 移管先dotfiles clone →
ユーザー名確認 → HM build/switch → `bootstrap.sh ime`と`bootstrap.sh input` →
GPU setup（必要時）→ 再ログイン・Phase 8確認。
初回の移行だけは上記の段階的な順序を守る。

## 調査元

- [Fcitx Wayland/Sway](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland/en)
- [Fedora Fcitx5](https://fedoraproject.org/wiki/I18N/Fcitx5)
- [XKB capslock symbols](https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/blob/master/symbols/capslock)
- [Fcitx TriggerKeys implementation](https://github.com/fcitx/fcitx5/blob/master/src/lib/fcitx/globalconfig.cpp)
- [xremap non-root setup](https://github.com/xremap/xremap/blob/master/doc/running_without_sudo.md)
- [Fedora Sway session config](https://gitlab.com/fedora/sigs/sway/sway-config-fedora)
- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)
- [Standalone Home Manager](https://nix-community.github.io/home-manager/)
- [HM non-NixOS GPU integration](https://github.com/nix-community/home-manager/blob/release-26.05/docs/manual/usage/gpu-non-nixos.md)
