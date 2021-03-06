/*
 * Copyright 2004-2018 H2 Group. Multiple-Licensed under the MPL 2.0,
 * and the EPL 1.0 (http://h2database.com/html/license.html).
 * Initial Developer: H2 Group
 */
package org.h2.value;

import java.lang.reflect.Array;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;

import org.h2.engine.Constants;
import org.h2.engine.SysProperties;
import org.h2.util.MathUtils;
import org.h2.util.StatementBuilder;

/**
 * Implementation of the ARRAY data type.
 */
public class ValueArray extends Value {

    /**
     * Empty array.
     */
    private static final Object EMPTY = get(new Value[0]);

    private final Class<?> componentType;
    private final Value[] values;
    private int hash;

    private ValueArray(Class<?> componentType, Value[] list) {
        this.componentType = componentType;
        this.values = list;
    }

    /**
     * Get or create a array value for the given value array.
     * Do not clone the data.
     *
     * @param list the value array
     * @return the value
     */
    public static ValueArray get(Value[] list) {
        return new ValueArray(Object.class, list);
    }

    /**
     * Get or create a array value for the given value array.
     * Do not clone the data.
     *
     * @param componentType the array class (null for Object[])
     * @param list the value array
     * @return the value
     */
    public static ValueArray get(Class<?> componentType, Value[] list) {
        return new ValueArray(componentType, list);
    }

    /**
     * Returns empty array.
     *
     * @return empty array
     */
    public static ValueArray getEmpty() {
        return (ValueArray) EMPTY;
    }

    @Override
    public int hashCode() {
        if (hash != 0) {
            return hash;
        }
        int h = 1;
        for (Value v : values) {
            h = h * 31 + v.hashCode();
        }
        hash = h;
        return h;
    }

    public Value[] getList() {
        return values;
    }

    @Override
    public int getType() {
        return Value.ARRAY;
    }

    public Class<?> getComponentType() {
        return componentType;
    }

    @Override
    public long getPrecision() {
        long p = 0;
        for (Value v : values) {
            p += v.getPrecision();
        }
        return p;
    }

    @Override
    public String getString() {
        StatementBuilder buff = new StatementBuilder("(");
        for (Value v : values) {
            buff.appendExceptFirst(", ");
            buff.append(v.getString());
        }
        return buff.append(')').toString();
    }

    @Override
    public int compareTypeSafe(Value o, CompareMode mode) {
        ValueArray v = (ValueArray) o;
        if (values == v.values) {
            return 0;
        }
        int l = values.length;
        int ol = v.values.length;
        int len = Math.min(l, ol);
        for (int i = 0; i < len; i++) {
            Value v1 = values[i];
            Value v2 = v.values[i];
            int comp = v1.compareTo(v2, /* TODO */ null, mode);
            if (comp != 0) {
                return comp;
            }
        }
        return Integer.compare(l, ol);
    }

    @Override
    public Object getObject() {
        int len = values.length;
        Object[] list = (Object[]) Array.newInstance(componentType, len);
        for (int i = 0; i < len; i++) {
            final Value value = values[i];
            if (!SysProperties.OLD_RESULT_SET_GET_OBJECT) {
                final int type = value.getType();
                if (type == Value.BYTE || type == Value.SHORT) {
                    list[i] = value.getInt();
                    continue;
                }
            }
            list[i] = value.getObject();
        }
        return list;
    }

    @Override
    public void set(PreparedStatement prep, int parameterIndex) throws SQLException {
        prep.setArray(parameterIndex, prep.getConnection().createArrayOf("NULL", (Object[]) getObject()));
    }

    @Override
    public StringBuilder getSQL(StringBuilder builder) {
        builder.append('(');
        int length = values.length;
        for (int i = 0; i < length; i++) {
            if (i > 0) {
                builder.append(", ");
            }
            values[i].getSQL(builder);
        }
        if (length == 1) {
            builder.append(',');
        }
        return builder.append(')');
    }

    @Override
    public String getTraceSQL() {
        StatementBuilder buff = new StatementBuilder("(");
        for (Value v : values) {
            buff.appendExceptFirst(", ");
            buff.append(v == null ? "null" : v.getTraceSQL());
        }
        return buff.append(')').toString();
    }

    @Override
    public int getDisplaySize() {
        long size = 0;
        for (Value v : values) {
            size += v.getDisplaySize();
        }
        return MathUtils.convertLongToInt(size);
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof ValueArray)) {
            return false;
        }
        ValueArray v = (ValueArray) other;
        if (values == v.values) {
            return true;
        }
        int len = values.length;
        if (len != v.values.length) {
            return false;
        }
        for (int i = 0; i < len; i++) {
            if (!values[i].equals(v.values[i])) {
                return false;
            }
        }
        return true;
    }

    @Override
    public int getMemory() {
        int memory = 32;
        for (Value v : values) {
            memory += v.getMemory() + Constants.MEMORY_POINTER;
        }
        return memory;
    }

    @Override
    public Value convertPrecision(long precision, boolean force) {
        if (!force) {
            return this;
        }
        int length = values.length;
        Value[] newValues = new Value[length];
        int i = 0;
        boolean modified = false;
        for (; i < length; i++) {
            Value old = values[i];
            Value v = old.convertPrecision(precision, true);
            if (v != old) {
                modified = true;
            }
            // empty byte arrays or strings have precision 0
            // they count as precision 1 here
            precision -= Math.max(1, v.getPrecision());
            if (precision < 0) {
                break;
            }
            newValues[i] = v;
        }
        if (i < length) {
            return get(componentType, Arrays.copyOf(newValues, i));
        }
        return modified ? get(componentType, newValues) : this;
    }

}
