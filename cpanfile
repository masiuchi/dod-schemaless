## -*- mode: perl; coding: utf-8 -*-

requires 'Data::ObjectDriver';
requires 'parent';
requires 'JSON';
requires 'Data::UUID';

on 'test' => sub {
    requires 'DBD::SQLite';
};

