//
//  VideosListViewController.swift
//  BackPlay Flow
//
//  Created by Unique Consulting Firm on 24/01/2025.
//

import UIKit
import AVKit
import MobileCoreServices
import AVFoundation
import Photos

class VideosListViewController: UIViewController ,UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addbtn: UIButton!
    @IBOutlet weak var noVideosLabel: UILabel!

    
    var videos: [String] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        roundCorner(button: addbtn)
        noVideosLabel.isHidden = true
        // Load saved videos from UserDefaults
        if let savedVideos = UserDefaults.standard.array(forKey: "VieosList") as? [String] {
            videos = savedVideos
        }
        
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
            try session.setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
        
    }
    
    
    func updateVideoList() {
        noVideosLabel.isHidden = !videos.isEmpty
    }
    
    @IBAction func addVideo(_ sender: Any) {
        requestPhotoLibraryPermission()
    }
    
    @IBAction func removeAllVideo(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "VieosList")
        videos.removeAll()
        updateVideoList()
        collectionView.reloadData()
    }
    
    
    @IBAction func settingsbtnPressed(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        newViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        newViewController.modalTransitionStyle = .crossDissolve
        self.present(newViewController, animated: true, completion: nil)
    }
    
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Permission granted, proceed with photo picker
                DispatchQueue.main.async {
                    self.showImagePicker()
                }
            case .denied, .restricted:
                // Permission denied or restricted
                DispatchQueue.main.async {
                    self.showPermissionDeniedAlert()
                }
            case .notDetermined:
                // If permission is not determined yet
                break
            @unknown default:
                break
            }
        }
    }
    
    func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "We need access to your photo library to select videos. Please enable it in Settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsPath.appendingPathComponent(videoURL.lastPathComponent)
            
            do {
                
                try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                videos.append(videoURL.lastPathComponent) // Save only the file name
                UserDefaults.standard.set(videos, forKey: "VieosList")
                collectionView.reloadData()
                updateVideoList()
            } catch {
                print("Error copying file: \(error)")
            }
        }
        updateVideoList()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper Method to Reconstruct Full Path
    func fullPath(for fileName: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(fileName)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DashboardCollectionViewCell
        
        let uniqueID = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(20)
        cell.titleLb.text = "Video \(uniqueID)"
        
        let videoURL = fullPath(for: videos[indexPath.row])
        
        if let thumbnail = generateThumbnail(for: videoURL) {
            cell.titleImage.image = thumbnail
        } else {
            cell.titleImage.image = UIImage(systemName: "video")
        }
        
        
        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = UIColor.systemYellow.cgColor
        cell.contentView.clipsToBounds = true
        
        
        cell.deletebtn.tag = indexPath.row
        cell.deletebtn.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewWidth = collectionView.bounds.width
        let spacing: CGFloat = 10
        let availableWidth = collectionViewWidth - (spacing * 2)
        let width = availableWidth / 2
        return CGSize(width: width - 20, height: width + 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // Adjust as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20) // Adjust as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videoURL = fullPath(for: videos[indexPath.row])
        
        // Set up the player and player view controller
        player = AVPlayer(url: videoURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        // Show the thumbnail first
        let thumbnailView = UIImageView(image: generateThumbnail(for: videoURL))
        thumbnailView.frame = self.view.bounds
        thumbnailView.contentMode = .scaleAspectFit
        self.view.addSubview(thumbnailView)
        
        // Add observer for when the video finishes playing
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // Present player after the thumbnail, then hide the thumbnail and show the player view
        present(playerViewController!, animated: true) {
            thumbnailView.removeFromSuperview() // Hide thumbnail when playback starts
            self.player?.play()
        }
    }
    
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        let index = sender.tag // Get the index of the video to delete
        
        guard index >= 0 && index < videos.count else {
               print("Error: Invalid index \(index)")
               return
           }
        videos.remove(at: index) // Remove the video from the array
         // Update UserDefaults
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }) { _ in
            UserDefaults.standard.set(self.videos, forKey: "VieosList")
            self.updateVideoList()
        }    }
    
    @objc func videoDidFinishPlaying(notification: Notification) {
        // Get the currently selected index
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems,
           let currentIndexPath = selectedIndexPaths.first {
            
            let currentIndex = currentIndexPath.row
            let nextIndex = (currentIndex + 1) % videos.count // Loop back to the first video
            
            // Create the next index path
            let nextIndexPath = IndexPath(item: nextIndex, section: currentIndexPath.section)
            
            // Get the next video's URL
            let nextVideoURL = fullPath(for: videos[nextIndex])
            
            // Replace the player item and play the next video
            player?.replaceCurrentItem(with: AVPlayerItem(url: nextVideoURL))
            player?.play()
            
            // Optionally, update the selection in the collection view
            collectionView.selectItem(at: nextIndexPath, animated: true, scrollPosition: .centeredVertically)
        }
    }
    
    func generateThumbnail(for url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            return nil
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    
    
}

class DashboardCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var titleLb: UILabel!
    @IBOutlet weak var deletebtn: UIButton!
}
