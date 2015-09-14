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

public class Constants {

    /**
     * Name of the abstract Roboconf component associated to an abstract Petals container
     */
    public static final String ROBOCONF_COMPONENT_ABTRACT_CONTAINER = "PetalsContainerTemplate";

    /**
     * Name of the abstract Roboconf component associated to an abstract Petals JBI component
     */
    public static final String ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT = "PetalsJBIComponent";

    /**
     * Name of the abstract Roboconf component associated to a Petals Binding Component
     */
    public static final String ROBOCONF_COMPONENT_BC_COMPONENT = "PetalsBC";

    /**
     * Name of the abstract Roboconf component associated to a Petals Service Engine
     */
    public static final String ROBOCONF_COMPONENT_SE_COMPONENT = "PetalsSE";

    /**
     * Name of the abstract Roboconf component associated to a Petals Service Unit
     */
    public static final String ROBOCONF_COMPONENT_SU_COMPONENT = "PetalsSU";

    /**
     * Name of the abstract Roboconf component associated to a Petals Shared Library
     */
    public static final String ROBOCONF_COMPONENT_SL_COMPONENT = "PetalsSL";

    /**
     * Name of the configuration parameter about hostname
     */
    public static final String CONTAINER_VARIABLE_NAME_IP = ROBOCONF_COMPONENT_ABTRACT_CONTAINER + ".ip";

    /**
     * Name of the configuration parameter about JMX port
     */
    public static final String CONTAINER_VARIABLE_NAME_JMXPORT = ROBOCONF_COMPONENT_ABTRACT_CONTAINER + ".jmxPort";

    /**
     * Name of the configuration parameter about JMX user
     */
    public static final String CONTAINER_VARIABLE_NAME_JMXUSER = ROBOCONF_COMPONENT_ABTRACT_CONTAINER + ".jmxUser";

    /**
     * Name of the configuration parameter about JMX password
     */
    public static final String CONTAINER_VARIABLE_NAME_JMXPASSWORD = ROBOCONF_COMPONENT_ABTRACT_CONTAINER
            + ".jmxPassword";

    /**
     * Name of the configuration parameter about the properties file of a JBI component
     */
    public static final String COMPONENT_VARIABLE_NAME_PROPERTIESFILE = ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT
            + ".propertiesFile";
}
