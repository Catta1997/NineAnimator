//
//  PlayerViewController.swift
//  NineAnimator
//
//  Created by Xule Zhou on 12/5/18.
//  Copyright © 2018 Marcus Zhou. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import SafariServices

class AnimeViewController: UITableViewController, ServerPickerSelectionDelegate {
    var avPlayerController: AVPlayerViewController!
    
    var link: AnimeLink? = nil
    
    var anime: Anime? = nil {
        didSet {
            DispatchQueue.main.async {
                self.informationCell?.animeDescription = self.anime?.description
                
                let sectionsNeededReloading: IndexSet = [1, 2]
                
                if self.anime == nil && oldValue != nil {
                    self.tableView.deleteSections(sectionsNeededReloading, with: .fade)
                }
                
                if let anime = self.anime {
                    self.server = anime.servers.first!.key
                    if oldValue == nil { self.tableView.insertSections(sectionsNeededReloading, with: .fade) }
                    else { self.tableView.reloadSections(sectionsNeededReloading, with: .fade) }
                }
            }
        }
    }
    
    var server: Anime.ServerIdentifier? = nil
    
    //Set episode will update the server identifier as well
    var episode: Episode? = nil {
        didSet { server = episode?.link.server }
    }
    
    var informationCell: AnimeDescriptionTableViewCell? = nil
    
    var selectedEpisodeCell: EpisodeTableViewCell? = nil
    
    var episodeRequestTask: NineAnimatorAsyncTask? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let link = self.link else { return }
        
        //Update anime title
        title = link.title
        
        NineAnimator.default.anime(with: link){
            anime, error in
            guard let anime = anime else {
                debugPrint("Error: \(error!)")
                return
            }
            self.anime = anime
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return anime == nil ? 1 : 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if case 0...1 = section { return 1 }
        
        if section == 2 {
            guard let serverIdentifier = server else { return 0 }
            guard let episodes = anime?.episodes[serverIdentifier] else { return 0 }
            return episodes.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "anime.description") as? AnimeDescriptionTableViewCell else { fatalError("cell with wrong type is dequeued") }
            cell.link = link
            cell.animeDescription = anime?.description
            cell.animeViewController = self
            informationCell = cell
            return cell
        }
        if indexPath.section == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "anime.serverPicker") as? ServerPickerTableViewCell else { fatalError("cell with wrong type is dequeued") }
            cell.servers = anime?.servers
            cell.delegate = self
            return cell
        }
        if indexPath.section == 2 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "anime.episode") as? EpisodeTableViewCell else { fatalError("unable to dequeue reuseable cell") }
            let episodes = anime!.episodes[server!]!
            cell.episodeLink = episodes[indexPath.item]
            return cell
        }
        fatalError()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? EpisodeTableViewCell else {
            debugPrint("Warning: Cell selection event received when the cell selected is not an EpisodeTableViewCell")
            return
        }
        
        if cell != selectedEpisodeCell {
            selectedEpisodeCell?.progressIndicator.hideActivityIndicator()
            episodeRequestTask?.cancel()
            cell.progressIndicator.showActivityIndicator()
            selectedEpisodeCell = cell
            
            episodeRequestTask = anime!.episode(with: cell.episodeLink!) {
                episode, error in
                guard let episode = episode else {
                    debugPrint("Error: \(error!)")
                    return
                }
                self.episode = episode
                
                debugPrint("Info: Episode target retrived for '\(episode.name)'")
                debugPrint("- Playback target: \(episode.target)")
                
                if episode.nativePlaybackSupported {
                    self.episodeRequestTask = episode.retrive {
                        item, error in
                        
                        self.episodeRequestTask = nil
                        
                        guard let item = item else {
                            debugPrint("Warn: Item not retrived \(error!), fallback to web access")
                            DispatchQueue.main.async {
                                let playbackController = SFSafariViewController(url: episode.target)
                                self.present(playbackController, animated: true)
                            }
                            return
                        }
                        
                        let playerController = AVPlayerViewController()
                        playerController.player = AVPlayer(playerItem: item)
                        
                        DispatchQueue.main.async {
                            playerController.player?.play()
                            self.present(playerController, animated: true)
                        }
                    }
                } else {
                    let playbackController = SFSafariViewController(url: episode.target)
                    self.present(playbackController, animated: true)
                    self.episodeRequestTask = nil
                }
            }
        }
    }
    
    func select(server: Anime.ServerIdentifier) {
        self.server = server
        tableView.reloadSections([2], with: .fade)
    }
}