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
package org.ow2.petals.roboconf.installer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.ow2.petals.roboconf.Constants.COMPONENT_VARIABLE_NAME_PROPERTIESFILE;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_IP;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPASSWORD;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPORT;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXUSER;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_CONTAINER;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_BC_COMPONENT;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_SU_COMPONENT;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import net.roboconf.core.model.beans.Component;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.plugin.api.PluginException;

import org.apache.commons.io.FileUtils;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
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

    @Rule
    public final TemporaryFolder tempFolder = new TemporaryFolder();

    @Test
    public void start() throws PluginException, DuplicatedServiceException, MissingServiceException,
            FileNotFoundException, IOException {

        final File rootFolder = this.tempFolder.newFolder();

        final Component abstractContainerComponent = new Component(ROBOCONF_COMPONENT_ABTRACT_CONTAINER);
        final Component containerComponent = new Component("my-container-component");
        containerComponent.extendComponent(abstractContainerComponent);
        final Component abstractJbiComponentComponent = new Component(ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT);
        final Component bcComponent = new Component(ROBOCONF_COMPONENT_BC_COMPONENT);
        bcComponent.extendComponent(abstractJbiComponentComponent);
        final Component suParentComponent = new Component("my-component-component");
        suParentComponent.extendComponent(bcComponent);

        final String containerName = "my-container";
        final Instance containerInstance = new Instance(containerName);
        containerInstance.component(containerComponent);
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_IP, "localhost");
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_JMXPORT, "7700");
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_JMXUSER, "petals");
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_JMXPASSWORD, "petals");

        final String componentName = "my-container-component-id";
        final Instance jbiComponentInstance = new Instance(componentName);
        jbiComponentInstance.component(suParentComponent);
        jbiComponentInstance.parent(containerInstance);
        final File expectedPropertiesFile = new File(new File(new File(rootFolder, "container-available"),
                containerName), componentName + ".properties");
        jbiComponentInstance.overriddenExports.put(COMPONENT_VARIABLE_NAME_PROPERTIESFILE, rootFolder
                + "/container-available/${container-name}/${component-name}.properties");

        final Component abstractSuComponent = new Component(ROBOCONF_COMPONENT_SU_COMPONENT);
        final Component suComponent = new Component("my-su-component");
        suComponent.extendComponent(abstractSuComponent);
        final Instance suInstance = new Instance(INSTANCE_SU_NAME).parent(jbiComponentInstance);
        suInstance.component(suComponent);
        jbiComponentInstance.getChildren().add(suInstance);
        final String variable1 = "variable1";
        final String value1 = "value1";
        suInstance.overriddenExports.put(variable1, value1);
        final String variable2 = "variable2";
        final String value2 = "value2";
        suInstance.overriddenExports.put(variable2, value2);

        final File componentInstanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(jbiComponentInstance);
        assertTrue(componentInstanceDirectory.mkdirs());
        final File suInstanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(suInstance);
        assertTrue(suInstanceDirectory.mkdirs());
        try {
            try (final InputStream componentInputStream = Thread.currentThread().getContextClassLoader()
                    .getResourceAsStream(componentName + ".zip")) {
                FileUtils.copyInputStreamToFile(componentInputStream, new File(componentInstanceDirectory,
                        componentName + ".zip"));
            }
            new FileOutputStream(new File(suInstanceDirectory, INSTANCE_SU_NAME + ".zip")).close();

            final PluginPetalsBcInstaller ppbi = new PluginPetalsBcInstaller();
            ppbi.setPetalsAdministrationApi(this.petalsAdminApi.getPetalsAdministrationFactory());
            ppbi.deploy(jbiComponentInstance);
            ppbi.start(jbiComponentInstance);

            final PluginPetalsSuInstaller ppsi = new PluginPetalsSuInstaller();
            ppsi.setPetalsAdministrationApi(this.petalsAdminApi.getPetalsAdministrationFactory());

            ppsi.deploy(suInstance);
            ppsi.start(suInstance);

            // Check the content of the properties file
            assertTrue(expectedPropertiesFile.exists());
            final Properties componentProperties = new Properties();
            componentProperties.load(new FileInputStream(expectedPropertiesFile));
            assertEquals(value1, componentProperties.getProperty(variable1));
            assertEquals(value2, componentProperties.getProperty(variable2));

            ppsi.stop(suInstance);
            ppsi.undeploy(suInstance);

            ppbi.stop(jbiComponentInstance);
            ppbi.undeploy(jbiComponentInstance);
        } finally {
            FileUtils.deleteDirectory(suInstanceDirectory);
            FileUtils.deleteDirectory(componentInstanceDirectory);
        }
    }
}
