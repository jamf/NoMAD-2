//
//  SRVResolver.swift
//  NoMAD
//
//  Created by Joel Rennich on 1/1/21.
//

import Foundation
import dnssd
import Combine

// Result needs errors, so here's one

public enum SRVResolverError: String, Error, Codable {
    case unableToComplete = "Unable to complete lookup"
}

public typealias SRVResolverResult = Result<SRVResult, SRVResolverError>
public typealias SRVResolverCompletion = (SRVResolverResult) -> Void

class SRVResolver {
    private let queue = DispatchQueue.init(label: "SRVResolution")
    private var dispatchSourceRead: DispatchSourceRead?;
    private var timeoutTimer: DispatchSourceTimer?;
    private var serviceRef: DNSServiceRef?
    private var socket: dnssd_sock_t = -1;
    private var query: String?
    
    // default to 5 sec lookups, we could maybe make this longer
    // but if you take more than 5 secs to look things up, you'll
    // probably have other problems
    
    private let timeout = TimeInterval(5)
    
    var results = [SRVRecord]()
    var completion: SRVResolverCompletion?
    
    // this processes any results from the system DNS resolver
    // we could parse all the things, but we don't really need the info...
    
    let queryCallback: DNSServiceQueryRecordReply = { (sdRef, flags, interfaceIndex, errorCode, fullname, rrtype, rrclass, rdlen, rdata, ttl, context) -> Void in
        
        guard let context = context else { return }
        
        let request: SRVResolver = SRVResolver.bridge(context)

        if let data = rdata?.assumingMemoryBound(to: UInt8.self),
           let record = SRVRecord(data: Data.init(bytes: data, count: Int(rdlen))) {
            request.results.append(record)
        }
        
        if ((flags & kDNSServiceFlagsMoreComing) == 0) {
            request.success()
        }
    }
    
    // These allow for the ObjC -> Swift conversion of a pointer
    // The DNS APIs are a bit... unique
    
    static func bridge<T:AnyObject>(_ obj : T) -> UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(obj).toOpaque();
    }
    
    static func bridge<T:AnyObject>(_ ptr : UnsafeMutableRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue();
    }
    
    func fail() {
        stopQuery()
        completion?(SRVResolverResult.failure(.unableToComplete))
    }
    
    func success() {
        stopQuery()
        let result = SRVResult(SRVRecords: results, query: query ?? "Unknown Query")
        completion?(SRVResolverResult.success(result))
    }
    
    private func stopQuery() {
        
        // be nice and clean things up
        self.timeoutTimer?.cancel()
        self.dispatchSourceRead?.cancel()
    }
    
    func resolve(query: String, completion: SRVResolverCompletion? = nil) {
        
        if let completion = completion {
            self.completion = completion
        }
        
        self.query = query
        let namec = query.cString(using: .utf8)
        
        let result = DNSServiceQueryRecord(&self.serviceRef, kDNSServiceFlagsReturnIntermediates, UInt32(0), namec,  UInt16(kDNSServiceType_SRV),  UInt16(kDNSServiceClass_IN), queryCallback, SRVResolver.bridge(self))
        
        switch result {
        case DNSServiceErrorType(kDNSServiceErr_NoError):
            
            guard let sdRef = self.serviceRef else {
                fail()
                return
            }
            
            self.socket = DNSServiceRefSockFD(self.serviceRef)
            
            guard self.socket != -1 else {
                fail()
                return
            }
            
            self.dispatchSourceRead = DispatchSource.makeReadSource(fileDescriptor: self.socket, queue: self.queue)
            
            self.dispatchSourceRead?.setEventHandler(handler: {
                let res = DNSServiceProcessResult(sdRef)
                if res != kDNSServiceErr_NoError {
                    self.fail()
                }
            })
            
            self.dispatchSourceRead?.setCancelHandler(handler: {
                DNSServiceRefDeallocate(self.serviceRef)
            })
            
            self.dispatchSourceRead?.resume()
            
            self.timeoutTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
            
            self.timeoutTimer?.setEventHandler(handler: {
                self.fail()
            })
            
            let deadline = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + UInt64(timeout * Double(NSEC_PER_SEC)))
            self.timeoutTimer?.schedule(deadline: deadline, repeating: .infinity, leeway: DispatchTimeInterval.never)
            self.timeoutTimer?.resume()
            
        default:
            self.fail()
        }
    }
}
