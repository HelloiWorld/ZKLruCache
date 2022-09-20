# ZKLruCache
swift写的线程安全的LRUCache

## Usage
`var lruCache = LRUCache<Int, String>(3)`

## Test
````
	private var lruCache = LRUCache<Int, String>(3)
    private let lock = NSLock()
    
    @objc func test() {
        var ord = 0
        var str = ""
        DispatchQueue(label: "1").async {
            while true {
                self.lruCache[ord] = str
            }
        }
        DispatchQueue(label: "2").async {
            while true {
                self.lruCache.enumerateAll { value in
                    print(value)
                }
            }
        }
        DispatchQueue(label: "3").async {
            while true {
                if ord % 5 == 0 {
                    self.lruCache.removeAll()
                }
            }
        }
        DispatchQueue(label: "4").async {
            while true {
                self.lock.lock()
                defer {
                    self.lock.unlock()
                }
                ord += 1
                str = "\(ord)"
            }
        }
    }