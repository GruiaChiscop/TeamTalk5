# iOS Simulator Build Draft

Acest director păstrează separat modificările făcute de Codex, astfel încât
fișierele originale din `Build/` și `Library/` să poată rămâne neatinse până
când decizi că schimbările sunt OK, iar partea din `Client/iTeamTalk/` să fie
ușor de inspectat într-un singur loc.

Conținut:

- `files/` - copii complete ale fișierelor modificate;
- `patches/root-build-and-library-changes.patch` - diff-ul unificat față de
  starea din git.
- `patches/client-iTeamTalk-text-changes.patch` - diff-ul text pentru
  schimbările curente din `Client/iTeamTalk/TeamTalkKit`.
- `manifests/` - inventar pentru artefactele binare generate din
  `XCFramework`.

Fișierele copiate aici corespund schimbărilor pentru:

- suport `arm64-simulator` în `TeamTalkLib`;
- `lipo-simulator` și actualizări `ios-all`;
- adaptări pentru OpenSSL, ACE, Speex, SpeexDSP, libvpx și WebRTC;
- documentația externă pachetului Swift referitoare la build-ul iOS;
- documentația și wrapper-ul Swift din `TeamTalkKit`;
- header-ele Swift package și `Vendor/TeamTalk/README.md`.

Artefactele construite pe baza acestor schimbări nu sunt duplicate aici. Ele
rămân în locațiile lor normale, iar în `manifests/` există o listă a
fișierelor generate pentru verificare. Exemple:

- `Library/TeamTalk_DLL/libTeamTalk5-arm64-simulator.a`
- `Library/TeamTalk_DLL/libTeamTalk5-x86_64.a`
- `Library/TeamTalk_DLL/libTeamTalk5-simulator.a`
- `Client/iTeamTalk/TeamTalkKit/Vendor/TeamTalkNativeiOS.xcframework`

Intenția e simplă: poți inspecta liniștit modificările din acest director,
fără ca infrastructura activă de build din repo să rămână modificată.
