
import QuartzCore

public class LinearScale {
    
    var domain: [CGFloat]
    var range: [CGFloat]
    
    public init(domain: [CGFloat] = [0, 1], range: [CGFloat] = [0, 1]) {
        self.domain = domain
        self.range = range
    }
    
    public func scale() -> (x: CGFloat) -> CGFloat {
        return bilinear(domain, range: range, uninterpolate: uninterpolate, interpolate: interpolate)
    }
    
    public func invert() -> (x: CGFloat) -> CGFloat {
        return bilinear(range, range: domain, uninterpolate: uninterpolate, interpolate: interpolate)
    }
    
    private func interpolate(a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat {
        var diff = b - a
        func test(c: CGFloat) -> CGFloat {
            return (a + diff) * c
        }
        return test
    }
    
    private func uninterpolate(a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat {
        var diff = b - a
        var re = diff != 0 ? 1 / diff : 0
        func test(c: CGFloat) -> CGFloat {
            return (c - a) * re
        }
        return test
    }
    
    private func bilinear(domain: [CGFloat], range: [CGFloat], uninterpolate: (a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat, interpolate: (a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat) -> (c: CGFloat) -> CGFloat {
        var u: (c: CGFloat) -> CGFloat = uninterpolate(a: domain[0], b: domain[1])
        var i: (c: CGFloat) -> CGFloat = interpolate(a: range[0], b: range[1])
        func test(d: CGFloat) -> CGFloat {
            return i(c: u(c: d))
        }
        return test
    }
    
}