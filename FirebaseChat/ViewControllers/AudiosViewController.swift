//
//  AudiosViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 6.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import AVFoundation

class AudiosViewController: UITableViewController, AVAudioPlayerDelegate {
    var audios : [String] = []
    var documentsURL : URL!
    var playedRecordIndex = -1
    var audioPlayer: AVAudioPlayer!
    var playedSlider : UISlider!
    var playTimer : Timer!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.documentsURL = URL.createFolder(folderName: "Records")
        self.audios = documentsURL?.listFilesFromDownloadsFolder() ?? []
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.playTimer?.invalidate()
        self.audioPlayer?.stop()
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.audios.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let play = cell.viewWithTag(1) as? UICustomButton
        let slider = cell.viewWithTag(2) as? UISlider
        let duration = cell.viewWithTag(3) as? UILabel
        slider!.smallerThumb(user: true)
        play?.clickIndex = indexPath.row
        play?.imageName = "play.fill"
        play?.addTarget(self, action: #selector(playRecord(sender:)), for: .touchUpInside)
        let audioAsset = AVURLAsset.init(url: documentsURL!.appendingPathComponent(self.audios[indexPath.row]), options: nil)
        let dur = audioAsset.duration
        let durationInSeconds = Int(CMTimeGetSeconds(dur))
        slider?.maximumValue = Float(CMTimeGetSeconds(dur) * 1000)
        duration?.text = durationInSeconds.getTime()
        return cell
    }
    
    @objc func playRecord(sender: UICustomButton){
        let clickIndex = sender.clickIndex
        let fileName = self.audios[clickIndex]
        if self.playedRecordIndex == -1 || self.playedRecordIndex == clickIndex {
            let bool = self.playedRecordIndex != -1
            self.playedRecordIndex = clickIndex
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
            self.playedSlider = cell?.viewWithTag(2) as? UISlider
            self.player(sender: sender, fileName: fileName, bool : bool)
        }else{
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
            let slider = cell?.viewWithTag(2) as? UISlider
            let play = cell?.viewWithTag(1) as? UICustomButton
            slider?.value = 0
            play?.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
            play?.imageName = "play.fill"
            self.playedRecordIndex = clickIndex
            let cell2 = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
            self.playedSlider = cell2?.viewWithTag(2) as? UISlider
            self.player(sender: sender, fileName: fileName, bool : false)
        }
        
    }
    
    func preparePlayer(fileName : String) {
        var error: NSError?
        do {
            let documentsURL = URL.createFolder(folderName: "Records")
            audioPlayer = try AVAudioPlayer(contentsOf: documentsURL!.appendingPathComponent(fileName))
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }
        if let err = error {
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 10.0
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playTimer?.invalidate()
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
        let slider = cell?.viewWithTag(2) as? UISlider
        let play = cell?.viewWithTag(1) as? UICustomButton
        slider?.value = 0
        play?.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
        play?.imageName = "play.fill"
    }
    
    func player(sender: UICustomButton, fileName : String, bool : Bool){
        if self.audioPlayer != nil && self.audioPlayer.isPlaying {
            self.audioPlayer.stop()
            playTimer?.invalidate()
        }
        if !bool {
            self.preparePlayer(fileName: fileName)
        }
        
        if sender.imageName == "play.fill"{
            sender.setImage(UIImage.init(systemName: "pause.fill"), for: .normal)
            sender.imageName = "pause.fill"
            self.audioPlayer.play()
            self.playTimer = Timer.scheduledTimer(timeInterval: 0.01, target:self, selector:#selector(self.updateSlider(timer:)), userInfo:nil, repeats:true)
        }else{
            sender.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
            sender.imageName = "play.fill"
            self.audioPlayer.stop()
            self.playTimer?.invalidate()
        }
        
    }
    
    @objc func updateSlider(timer: Timer){
        self.playedSlider.value = Float(self.audioPlayer.currentTime * 1000)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let fileName = self.audios[indexPath.row]
            self.audios.remove(at: indexPath.row)
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }, completion: { result in 
                URL.deleteFile(documentPath: self.documentsURL!.appendingPathComponent(fileName).path)
            })
        }
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
