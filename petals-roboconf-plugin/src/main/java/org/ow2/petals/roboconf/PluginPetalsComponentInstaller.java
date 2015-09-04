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

import java.util.Map.Entry;
import java.util.Properties;

import net.roboconf.core.model.beans.Import;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.beans.Instance.InstanceStatus;
import net.roboconf.plugin.api.PluginException;

import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;

public abstract class PluginPetalsComponentInstaller extends PluginPetalsJbiArtifactInstaller {

    public PluginPetalsComponentInstaller() throws DuplicatedServiceException, MissingServiceException {
        super();
    }

    @Override
    protected Properties getConfigurationProperties(final Instance componentInstance) {

        final Properties configurationProperties = super.getConfigurationProperties(componentInstance);
        for (final Entry<String, String> entry : componentInstance.overriddenExports.entrySet()) {
            configurationProperties.setProperty(entry.getKey(), entry.getValue());
        }

        return configurationProperties;
    }

    @Override
    public void update(final Instance instance, final Import importChanged, final InstanceStatus statusChanged)
            throws PluginException {
        // TODO: Reload properties conf file for JBI component
    }
}
