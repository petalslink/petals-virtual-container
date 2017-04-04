/**
 * Copyright (c) 2015-2017 Linagora
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
 * along with this program/library; If not, see http://www.gnu.org/licenses/
 * for the GNU Lesser General Public License version 2.1.
 */
package org.ow2.petals.roboconf.installer;

import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;

import net.roboconf.core.model.beans.Import;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.beans.Instance.InstanceStatus;
import net.roboconf.plugin.api.PluginException;
import net.roboconf.plugin.api.PluginInterface;

public class PluginPetalsSlInstaller extends PluginPetalsJbiArtifactInstaller implements PluginInterface {

    private static final String PLUGIN_NAME = "petals-sl-installer";

    public PluginPetalsSlInstaller() throws DuplicatedServiceException, MissingServiceException {
        super();
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {
        // NOP: Hack to workaround https://github.com/roboconf/roboconf-platform/issues/331
        // TODO: Remove when https://github.com/roboconf/roboconf-platform/issues/331 will be fixed
    }

    @Override
    public void start(final Instance instance) throws PluginException {
        // NOP: Hack to workaround https://github.com/roboconf/roboconf-platform/issues/331
        // TODO: Remove when https://github.com/roboconf/roboconf-platform/issues/331 will be fixed
        super.deploy(instance);
        super.start(instance);
    }

    @Override
    public void update(final Instance instance, final Import importChanged, final InstanceStatus statusChanged)
            throws PluginException {
        // NOP
    }

    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }

    @Override
    protected String getManagedArtifactType() {
        return "SL";
    }

}
