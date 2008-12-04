/**
 * Copyright (c) 2008 Red Hat, Inc.
 *
 * This software is licensed to you under the GNU General Public License,
 * version 2 (GPLv2). There is NO WARRANTY for this software, express or
 * implied, including the implied warranties of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
 * along with this software; if not, see
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
 * 
 * Red Hat trademarks are not licensed under GPLv2. No permission is
 * granted to use or replicate Red Hat trademarks that are incorporated
 * in this software or its documentation. 
 */

package com.redhat.rhn.manager.kickstart.cobbler;

import com.redhat.rhn.common.validator.ValidatorError;
import com.redhat.rhn.domain.kickstart.KickstartData;
import com.redhat.rhn.domain.kickstart.KickstartFactory;
import com.redhat.rhn.domain.kickstart.KickstartableTree;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


/**
 * This command finds profiles that have been changed on the cobbler server and syncs 
 *  those changes to the satellite
 * @version $Rev$
 */
public class CobblerProfileSyncCommand extends CobblerCommand {
  
    /**
     * Command to sync unsynced Kickstart profiles to cobbler. 
     */
    public CobblerProfileSyncCommand() {
        super();
    }
    
    
    
    /**
     *  Get a map of CobblerID -> profileMap from cobbler
     * @return a list of cobbler profile names 
     */
    private Map<String, Map> getModifiedProfileNames() {
        Map<String, Map> toReturn = new HashMap<String, Map>();
        List<Map> profiles = (List<Map>)invokeXMLRPC("get_profiles", xmlRpcToken);
        for (Map profile : profiles) {
                toReturn.put((String)profile.get("uid"), profile);
        }
        return toReturn;
    }    
    

    /**
     * {@inheritDoc}
     */
    @Override
    public ValidatorError store() {
        //First are there any profiles within spacewalk that aren't within cobbler
        List<KickstartData> profiles = KickstartFactory.listAllKickstartData();
        Map<String, Map> profileNames = getModifiedProfileNames();
        for (KickstartData profile : profiles) {
            if (!profileNames.containsKey(profile.getCobblerId())) {
                createProfile(profile);
            }
        }
        

        //Are there any profiles on cobbler that have changed 
        Map<String, Map> cobblerProfiles = getModifiedProfileNames();        
        for (KickstartData profile : profiles) {
            if (cobblerProfiles.containsKey(profile.getCobblerId())) {
                Map cobProfile = cobblerProfiles.get(profile.getCobblerId());
                if ((Integer)cobProfile.get("mtime") > profile.getModified().getTime()) {
                    syncProfileToSpacewalk(cobProfile, profile);
                }
            }
        }  
        
        
        return null;
    }
    
    private void createProfile(KickstartData profile) {
        CobblerProfileCreateCommand creator = new CobblerProfileCreateCommand(profile, 
                                        user);
        creator.store();
    }

    
    /**
     * Sync s the following things:
     *  Distro (if applicable)
     *  
     * then overwrites the 'kickstart' attribute within the cobbler profile
     *      (in case they changed it to something spacewalk doesn't know about)
     * @param cobblerProfile
     * @param profile
     */
    private void syncProfileToSpacewalk(Map cobblerProfile, KickstartData profile) {

        //Do we need to sync the distro?
        Map distro = (Map) invokeXMLRPC("get_distro", cobblerProfile.get("distro"));
        if (!distro.get("uid").equals(profile.getTree().getCobblerId())) {
            //lookup the distro locally:
            KickstartableTree tree = KickstartFactory.lookupKickstartTreeByCobblerId(
                       (String)distro.get("uid"));
            if (tree == null) {
                //TODO Throw ERRROR/LOG
            }
            else {
                profile.setTree(tree);
            }
        }
        
        //Now re-set the filename in case someone set it incorrectly
        String handle = (String) invokeXMLRPC("get_profile_handle", 
                cobblerProfile.get("name"), xmlRpcToken);
        invokeXMLRPC("modify_profile", handle, "kickstart", profile.getCobblerFileName(), 
                xmlRpcToken);
        invokeXMLRPC("save_profile", handle, xmlRpcToken);
        
        //Lets update the modified date just to make sure
        profile.setModified(new Date());
    }

}
