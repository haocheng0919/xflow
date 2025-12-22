import Foundation

struct CryptoAddress: Identifiable {
    let id = UUID()
    let address: String
    let type: ChainType
    let range: Range<String.Index>
}

enum ChainType {
    case solana
    case evm
}

@MainActor
class Web3Utils {
    static let shared = Web3Utils()
    
    // Regex Patterns
    private let solanaPattern = "[1-9A-HJ-NP-Za-km-z]{32,44}"
    private let evmPattern = "0x[a-fA-F0-9]{40}"
    
    private init() {}
    
    func extractAddresses(from text: String) -> [CryptoAddress] {
        var results: [CryptoAddress] = []
        
        // Find Solana
        if let regex = try? NSRegularExpression(pattern: solanaPattern) {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let address = String(text[range])
                    results.append(CryptoAddress(address: address, type: .solana, range: range))
                }
            }
        }
        
        // Find EVM
        if let regex = try? NSRegularExpression(pattern: evmPattern) {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let address = String(text[range])
                    results.append(CryptoAddress(address: address, type: .evm, range: range))
                }
            }
        }
        
        return results
    }
    
    func getTradingUrl(for address: String, type: ChainType, dex: String) -> URL? {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch dex {
        case "GMGN":
            if type == .solana {
                return URL(string: "https://gmgn.ai/sol/token/\(cleanAddress)")
            } else {
                return URL(string: "https://gmgn.ai/eth/token/\(cleanAddress)") // Default to ETH for EVM
            }
        case "Axiom":
             return URL(string: "https://www.axiom.xyz/") 
        case "Photon":
            if type == .solana {
                return URL(string: "https://photon-sol.tinyastro.io/en/lp/\(cleanAddress)")
            } else {
                return nil 
            }
        default:
            return nil
        }
    }
}
