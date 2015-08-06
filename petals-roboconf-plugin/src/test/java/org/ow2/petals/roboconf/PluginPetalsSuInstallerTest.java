/**
 * Copyright (c) 2015 Linagora
 * 
 * This program/library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or (at your
 * option) any later version.
 * 
 * This program/library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program/library; If not, see <http://www.gnu.org/licenses/>
 * for the GNU Lesser General Public License version 2.1.
 */
package org.ow2.petals.roboconf;

import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import net.roboconf.core.model.beans.Component;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.plugin.api.PluginException;

import org.apache.commons.io.FileUtils;
import org.junit.Rule;
import org.junit.Test;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;
import org.ow2.petals.admin.junit.PetalsAdministrationApi;

/**
 * Unit tests of {@link PluginPetalsSuInstaller}
 * 
 * @author Christophe DENEUX - Linagora
 *
 */
public class PluginPetalsSuInstallerTest {

    private static final String INSTANCE_SU_NAME = "my-su-instance";

    @Rule
    public final PetalsAdministrationApi petalsAdminApi = new PetalsAdministrationApi();

    @Test
    public void start() throws PluginException, DuplicatedServiceException, MissingServiceException,
            FileNotFoundException, IOException {

        final Component suAbstractContainer = new Component(
                PluginPetalsSuInstaller.ROBOCONF_COMPONENT_ABTRACT_CONTAINER);
        final Component suContainer = new Component("my-container-component");
        suContainer.extendComponent(suAbstractContainer);
        suContainer.exportedVariables.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_IP, "localhost");
        suContainer.exportedVariables.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_JMXPORT, "7700");
        suContainer.exportedVariables.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_JMXUSER, "petals");
        suContainer.exportedVariables.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_JMXPASSWORD, "petals");
        final Component suAbstractParentComponent = new Component(
                PluginPetalsSuInstaller.ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT);
        final Component suParentComponent = new Component("my-component-component");
        suParentComponent.extendComponent(suAbstractParentComponent);
        final Instance instance = new Instance(INSTANCE_SU_NAME).parent(new Instance("component-id").component(
                suParentComponent).parent(new Instance().component(suContainer)));

        final File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(instance);
        assertTrue(instanceDirectory.mkdirs());
        try {
            new FileOutputStream(new File(instanceDirectory, INSTANCE_SU_NAME + ".zip")).close();

            final PluginPetalsSuInstaller ppsi = new PluginPetalsSuInstaller();
            ppsi.setPetalsAdministrationApi(this.petalsAdminApi.getPetalsAdministrationFactory());

            ppsi.deploy(instance);
            ppsi.start(instance);
            ppsi.stop(instance);
            ppsi.undeploy(instance);
        } finally {
            FileUtils.deleteDirectory(instanceDirectory);
        }
    }

}
