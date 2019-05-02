import Foundation
import SourceKittenFramework

extension Configuration {
    public func lintableFiles(inPath path: String, forceExclude: Bool) -> [File] {
        return lintablePaths(inPath: path, forceExclude: forceExclude).compactMap(File.init(pathDeferringReading:))
    }

    internal func lintablePaths(inPath path: String, forceExclude: Bool,
                                fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
        if path.isFile && !forceExclude {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let includedPaths = included.parallelFlatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: self.rootPath)
        }
        return filterExcludedPaths(fileManager: fileManager, in: pathsForPath, includedPaths)
    }
}

extension Configuration {
    public func filterExcludedPaths(fileManager: LintableFileManager = FileManager.default,
                                    in paths: [String]...) -> [String] {
#if os(Linux)
        let allPaths = paths.reduce([], +)
        let result = NSMutableOrderedSet(capacity: allPaths.count)
        result.addObjects(from: allPaths)
#else
        let result = NSMutableOrderedSet(array: paths.reduce([], +))
#endif
        let excludedPaths = self.excludedPaths(fileManager: fileManager)
        result.minusSet(Set(excludedPaths))

        let excludeRegExs: [NSRegularExpression] = excluded.compactMap { pattern in
            return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        }

        // swiftlint:disable:next force_cast
        return result.map { $0 as! String }.filter { path in
            let range = NSRange(path.startIndex..., in: path)
            let exclude = excludeRegExs.contains(where: {
                $0.firstMatch(in: path, options: [], range: range) != nil
            })
            
            if exclude {
                print("Skip linting regex '\(path)'")
            }
            
            return !exclude
        }
    }

    internal func excludedPaths(fileManager: LintableFileManager) -> [String] {
        return excluded
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap {
                fileManager.filesToLint(inPath: $0, rootDirectory: self.rootPath)
            }
    }
}
