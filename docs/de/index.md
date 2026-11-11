# FreeSynergy.Zentinel

Zentinel ist das Tor eines FreeSynergy-Servers: Es nimmt alle öffentlichen Verbindungen an, beendet TLS und reicht Anfragen an die Programme dahinter weiter. Zentinel startet zuerst, danach Kanidm (der Anmeldedienst) dahinter.

- [Fähigkeiten](capabilities.md): was Zentinel bietet und was nicht, mit Quellen.
- [Konfiguration](configuration.md): die öffentlichen KDL-Voreinstellungen und was aus dem Tresor kommt.
- [Spiegel](mirror.md): woher das Paket kommt und wie es geprüft wird.

Zentinel hat vorerst keinen eigenen Login: Programme melden sich selbst per OIDC bei Kanidm an. Ein Login-Agent für Programme ohne eigenen Login steht auf der [Roadmap](../ROADMAP.md).

Sprache: [English](../en/index.md)
