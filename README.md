# Code for Dorsal prefrontal cortex drives perseverative behavior in mice, Lebedeva et al.

In order to run the code, please download the data from here: https://doi.org/10.6084/m9.figshare.31231741  

This folder contains data in three folders: figure1 (behaviour only), figure 245 (behavioural and ephys data), figure 67 (optogenetics data).    

Within each of the three folders, you will find a folder for each mouse and within that you will find a folder for each date.    

Inside, there are some (depending on the experiment) of the following files:    
trials.choices.npy (-1 for left, 1 for right wheel turn)  

trials.correct_answers.npy (-1 for left, 1 for right wheel turn)  

trials.feedback.npy (0 for white noise, 1 for liquid reward)  

trials.go_cue_times.npy (in seconds)  

trials.movement_times.npy (in seconds)  

trials.feedback_times.npy (in seconds)  

trials.laser_at_go_cue.npy (0 if no laser at go cue, 1 if laser ON)  

trials.laser_at_feedback.npy (0 if no laser at feedback time, 1 if laser ON)  

spikes.times.npy (in samples; sampling frequency 30 kHz)  

spikes.clusters.npy (cluster ID for every spike; only non-noise clusters)  

clusters.brain_location_ccf_2017.txt (name of brain region for every cluster; ordered by cluster index, not cluster ID)  

trials.:star:.npy files are size (1, nTrials)  ; spikes.:star:.npy are size (nSpikes,1) ; clusters.:star:.npy are size (nClusters,1).  



To run the code, save the data folders onto your computer and change the loadPath... files to point to their location.  

