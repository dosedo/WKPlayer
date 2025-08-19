//
//  WKMacro.h
//  WKPlayer
//
//  Created by Kidsmiless on 16/6/29.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#ifndef WKMacro_h
#define WKMacro_h

#import <Foundation/Foundation.h>

#define WKWeakify(obj) __weak typeof(obj) weak_obj = obj;
#define WKStrongify(obj) __strong typeof(weak_obj) obj = weak_obj;

#ifdef DEBUG
#define WKPlayerLog(...) NSLog(__VA_ARGS__)
#else
#define WKPlayerLog(...)
#endif

#define WKGet0Map(ret, name0, obj) - (ret)name0 {return obj.name0;}
#define WKGet1Map(ret, name0, t0, obj) - (ret)name0:(t0)n0 {return [obj name0:n0];}
#define WKGet00Map(ret, name0, name00, obj) - (ret)name0 {return obj.name00;}
#define WKGet11Map(ret, name0, name00, t0, obj) - (ret)name0:(t0)n0 {return [obj name00:n0];}

#define WKSet1Map(ret, name0, t0, obj) - (ret)name0:(t0)n0 {[obj name0:n0];}
#define WKSet2Map(ret, name0, t0, name1, t1, obj) - (ret)name0:(t0)n0 name1:(t1)n1 {[obj name0:n0 name1:n1];}
#define WKSet11Map(ret, name0, name00, t0, obj) - (ret)name0:(t0)n0 {[obj name00:n0];}
#define WKSet22Map(ret, name0, name00, t0, name1, name11, t1, obj) - (ret)name0:(t0)n0 name1:(t1)n1 {[obj name00:n0 name11:n1];}

#endif
