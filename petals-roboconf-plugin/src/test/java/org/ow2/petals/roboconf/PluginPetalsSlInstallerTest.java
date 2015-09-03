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
import java.io.IOException;
import java.io.InputStream;

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
 * Unit tests of {@link PluginPetalsSlInstaller}
 * 
 * @author Christophe DENEUX - Linagora
 *
 */
public class PluginPetalsSlInstallerTest {

    private static final String INSTANCE_SL_NAME = "petals-sl-postgresql-9.4-1201-jdbc4";

    @Rule
    public final PetalsAdministrationApi petalsAdminApi = new PetalsAdministrationApi();

    @Test
    public void start() throws PluginException, DuplicatedServiceException, MissingServiceException,
            FileNotFoundException, IOException {

        final Component abstractContainerComponent = new Component(
                PluginPetalsSuInstaller.ROBOCONF_COMPONENT_ABTRACT_CONTAINER);
        final Component containerComponent = new Component("my-container-component");
        containerComponent.extendComponent(abstractContainerComponent);

        final Instance containerInstance = new Instance("my-container");
        containerInstance.component(containerComponent);
        containerInstance.overriddenExports.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_IP, "localhost");
        containerInstance.overriddenExports.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_JMXPORT, "7700");
        containerInstance.overriddenExports.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_JMXUSER, "petals");
        containerInstance.overriddenExports.put(PluginPetalsSuInstaller.CONTAINER_VARIABLE_NAME_JMXPASSWORD, "petals");
        final Instance slInstance = new Instance(INSTANCE_SL_NAME).parent(containerInstance);
        slInstance.component(new Component(PluginPetalsSuInstaller.ROBOCONF_COMPONENT_SL_COMPONENT));

        final File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(slInstance);
        assertTrue(instanceDirectory.mkdirs());
        try {
            try (final InputStream slInputStream = Thread.currentThread().getContextClassLoader()
                    .getResourceAsStream("sl-archive.zip")) {
                FileUtils.copyInputStreamToFile(slInputStream, new File(instanceDirectory, INSTANCE_SL_NAME + ".zip"));
            }

            final PluginPetalsSlInstaller ppsi = new PluginPetalsSlInstaller();
            ppsi.setPetalsAdministrationApi(this.petalsAdminApi.getPetalsAdministrationFactory());

            ppsi.deploy(slInstance);
            ppsi.start(slInstance);
            ppsi.stop(slInstance);
            ppsi.undeploy(slInstance);
        } finally {
            FileUtils.deleteDirectory(instanceDirectory);
        }
    }

}