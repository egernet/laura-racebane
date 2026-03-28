import Foundation
import MultipeerConnectivity

/// Wrapper rundt MultipeerConnectivity for lokal multiplayer
class SessionManager: NSObject, ObservableObject {

    // MARK: - Published state

    @Published var isHost: Bool = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isConnected: Bool = false
    @Published var discoveredHosts: [MCPeerID] = []

    // MARK: - Callbacks

    var onMessageReceived: ((GameMessage, MCPeerID) -> Void)?
    var onPeerConnected: ((MCPeerID) -> Void)?
    var onPeerDisconnected: ((MCPeerID) -> Void)?

    // MARK: - Private

    private let serviceType = "racebane"
    private let myPeerId: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        self.myPeerId = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
    }

    var myId: String { myPeerId.displayName }

    // MARK: - Host

    /// Start som host (advertiser)
    func startHosting() {
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    /// Stop hosting
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    // MARK: - Client

    /// Start søgning efter hosts
    func startBrowsing() {
        isHost = false
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    /// Stop søgning
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    /// Forbind til en host
    func joinHost(_ hostPeer: MCPeerID) {
        browser?.invitePeer(hostPeer, to: session, withContext: nil, timeout: 10)
    }

    // MARK: - Messaging

    /// Send besked til alle forbundne peers
    func sendToAll(_ message: GameMessage, reliable: Bool = true) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try encoder.encode(message)
            try session.send(data, toPeers: session.connectedPeers,
                           with: reliable ? .reliable : .unreliable)
        } catch {
            print("Send fejl: \(error)")
        }
    }

    /// Send besked til specifik peer
    func send(_ message: GameMessage, to peer: MCPeerID, reliable: Bool = true) {
        do {
            let data = try encoder.encode(message)
            try session.send(data, toPeers: [peer], with: reliable ? .reliable : .unreliable)
        } catch {
            print("Send fejl: \(error)")
        }
    }

    // MARK: - Cleanup

    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        DispatchQueue.main.async {
            self.connectedPeers = []
            self.isConnected = false
            self.discoveredHosts = []
        }
    }
}

// MARK: - MCSessionDelegate

extension SessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            self.isConnected = !session.connectedPeers.isEmpty

            switch state {
            case .connected:
                self.onPeerConnected?(peerID)
            case .notConnected:
                self.onPeerDisconnected?(peerID)
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try decoder.decode(GameMessage.self, from: data)
            DispatchQueue.main.async {
                self.onMessageReceived?(message, peerID)
            }
        } catch {
            print("Decode fejl: \(error)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension SessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accepter automatisk invitationer
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension SessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.discoveredHosts.contains(peerID) {
                self.discoveredHosts.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredHosts.removeAll { $0 == peerID }
        }
    }
}
