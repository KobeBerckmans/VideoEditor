import UIKit
import AVFoundation
import GPUImage

class VideoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    var videoURL: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
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
        let movie = GPUImageMovie(url: videoURL)
        
        // Hier kun je de filter kiezen die je wilt toepassen
        let gpuFilter = GPUImageSepiaFilter() // Voorbeeldfilter: Sepia
        movie.addTarget(gpuFilter)
        
        let filterView = GPUImageView(frame: previewView.bounds)
        previewView.addSubview(filterView)
        
        gpuFilter.addTarget(filterView)
        movie.startProcessing()
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
                    print("Export complete to: \(outputURL)")
                } else {
                    print("Export failed: \(String(describing: exportSession?.error))")
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
        return 3 // Aantal filters (pas dit aan naar behoefte)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath)
        // Configuratie van filter cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Hier filter toepassen
        applyFilter("CISepiaTone") // Voorbeeldfilter, pas dit aan naar behoefte
    }
}
