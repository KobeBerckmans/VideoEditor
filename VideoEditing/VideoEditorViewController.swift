import UIKit
import AVFoundation
import CoreImage
import CoreGraphics
import Dispatch
import GPUImage

class VideoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    var videoURL: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var context = CIContext() // Voor Core Image
    var filter: CIFilter?
    
    // UI Outlets
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var trimSlider: UISlider!
    @IBOutlet weak var exportButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterCollectionView()
    }

    // MARK: - Video Import
    @IBAction func importVideo(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let url = info[.mediaURL] as? URL {
            videoURL = url
            setupPlayer(with: url)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Video Player
    func setupPlayer(with url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = previewView.bounds
        playerLayer?.videoGravity = .resizeAspect
        if let playerLayer = playerLayer {
            previewView.layer.addSublayer(playerLayer)
        }
        player?.play()
    }

    // MARK: - Filter Application
    func applyFilter(_ filterName: String) {
        guard let videoURL = videoURL else { return }
        filter = CIFilter(name: filterName)
        let movie = GPUImageMovie(url: videoURL)
        let gpuFilter = GPUImageFilter() // Pas hier GPUImage filters aan
        movie.addTarget(gpuFilter)
        gpuFilter.addTarget(previewView)
        movie.startProcessing()
    }

    // MARK: - Video Trimming
    func trimVideo(start: Float, end: Float, completion: @escaping (URL?) -> Void) {
        guard let videoURL = videoURL else { return }
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        let trimmedURL = URL(fileURLWithPath: NSTemporaryDirectory() + "trimmed.mov")
        exportSession?.outputURL = trimmedURL
        exportSession?.outputFileType = .mov
        let startTime = CMTime(seconds: Double(start), preferredTimescale: 600)
        let endTime = CMTime(seconds: Double(end), preferredTimescale: 600)
        exportSession?.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession?.exportAsynchronously {
            if exportSession?.status == .completed {
                completion(trimmedURL)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Video Export
    @IBAction func exportVideo(_ sender: UIButton) {
        guard let videoURL = videoURL else { return }
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + "final.mov")
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mov
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession?.status == .completed {
                    print("Export complete!")
                } else {
                    print("Export failed.")
                }
            }
        }
    }

    // MARK: - Helper Methods
    func setupFilterCollectionView() {
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension VideoEditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // Aantal filters
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath)
        // Configuratie van filter cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Hier filter toepassen
        applyFilter("CISepiaTone") // Voorbeeldfilter
    }
}
