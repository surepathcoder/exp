"""add_wallets_and_numeric

Revision ID: 9ee8c4416213
Revises: d63a78da20ce
Create Date: 2026-05-23 09:44:41.269269

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9ee8c4416213'
down_revision: Union[str, None] = 'd63a78da20ce'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    from sqlalchemy.dialects import postgresql
    
    # 1. Create wallettypeenum type safely if it doesn't exist
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'wallettypeenum') THEN
                CREATE TYPE wallettypeenum AS ENUM ('cash', 'bank', 'mobile_money', 'credit_card');
            END IF;
        END$$;
    """)

    # 2. Get existing types with create_type=False to avoid automatic creation attempts
    wallet_type_enum = postgresql.ENUM('cash', 'bank', 'mobile_money', 'credit_card', name='wallettypeenum', create_type=False)
    currency_enum = postgresql.ENUM('USD', 'TZS', 'KES', name='currencyenum', create_type=False)

    # 3. Create wallets table
    op.create_table('wallets',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('type', wallet_type_enum, server_default='cash', nullable=False),
        sa.Column('currency', currency_enum, nullable=False),
        sa.Column('opening_balance', sa.Numeric(precision=18, scale=2), server_default='0.00', nullable=False),
        sa.Column('balance', sa.Numeric(precision=18, scale=2), server_default='0.00', nullable=False),
        sa.Column('icon', sa.String(), server_default='wallet', nullable=False),
        sa.Column('color', sa.String(), server_default='#3D1B5B', nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='true', nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], name='fk_wallets_users'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_wallets_id'), 'wallets', ['id'], unique=False)

    # 4. Add wallet columns and foreign keys to other tables
    op.add_column('expenses', sa.Column('wallet_id', sa.Integer(), nullable=True))
    op.alter_column('expenses', 'amount',
               existing_type=sa.DOUBLE_PRECISION(precision=53),
               type_=sa.Numeric(precision=18, scale=2),
               existing_nullable=False)
    op.create_foreign_key('fk_expenses_wallet_id', 'expenses', 'wallets', ['wallet_id'], ['id'])
    
    op.add_column('incomes', sa.Column('wallet_id', sa.Integer(), nullable=True))
    op.alter_column('incomes', 'amount',
               existing_type=sa.DOUBLE_PRECISION(precision=53),
               type_=sa.Numeric(precision=18, scale=2),
               existing_nullable=False)
    op.create_foreign_key('fk_incomes_wallet_id', 'incomes', 'wallets', ['wallet_id'], ['id'])
    
    op.add_column('transfers', sa.Column('wallet_from_id', sa.Integer(), nullable=True))
    op.add_column('transfers', sa.Column('wallet_to_id', sa.Integer(), nullable=True))
    op.alter_column('transfers', 'amount_from',
               existing_type=sa.DOUBLE_PRECISION(precision=53),
               type_=sa.Numeric(precision=18, scale=2),
               existing_nullable=False)
    op.alter_column('transfers', 'amount_to',
               existing_type=sa.DOUBLE_PRECISION(precision=53),
               type_=sa.Numeric(precision=18, scale=2),
               existing_nullable=False)
    op.create_foreign_key('fk_transfers_wallet_from_id', 'transfers', 'wallets', ['wallet_from_id'], ['id'])
    op.create_foreign_key('fk_transfers_wallet_to_id', 'transfers', 'wallets', ['wallet_to_id'], ['id'])


def downgrade() -> None:
    # 1. Drop foreign keys and columns
    op.drop_constraint('fk_transfers_wallet_to_id', 'transfers', type_='foreignkey')
    op.drop_constraint('fk_transfers_wallet_from_id', 'transfers', type_='foreignkey')
    op.alter_column('transfers', 'amount_to',
               existing_type=sa.Numeric(precision=18, scale=2),
               type_=sa.DOUBLE_PRECISION(precision=53),
               existing_nullable=False)
    op.alter_column('transfers', 'amount_from',
               existing_type=sa.Numeric(precision=18, scale=2),
               type_=sa.DOUBLE_PRECISION(precision=53),
               existing_nullable=False)
    op.drop_column('transfers', 'wallet_to_id')
    op.drop_column('transfers', 'wallet_from_id')
    
    op.drop_constraint('fk_incomes_wallet_id', 'incomes', type_='foreignkey')
    op.alter_column('incomes', 'amount',
               existing_type=sa.Numeric(precision=18, scale=2),
               type_=sa.DOUBLE_PRECISION(precision=53),
               existing_nullable=False)
    op.drop_column('incomes', 'wallet_id')
    
    op.drop_constraint('fk_expenses_wallet_id', 'expenses', type_='foreignkey')
    op.alter_column('expenses', 'amount',
               existing_type=sa.Numeric(precision=18, scale=2),
               type_=sa.DOUBLE_PRECISION(precision=53),
               existing_nullable=False)
    op.drop_column('expenses', 'wallet_id')

    # 2. Drop wallets table
    op.drop_index(op.f('ix_wallets_id'), table_name='wallets')
    op.drop_table('wallets')

    # 3. Drop wallettypeenum type
    op.execute("DROP TYPE IF EXISTS wallettypeenum CASCADE")
