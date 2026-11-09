import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Mission = {
  id: string;
  kind: string;
  title: string;
  description: string;
  issuer: string;
  orders: string[];
  difficulty: number;
  reward_theme: string;
  rewards: { id: string; name: string; description: string }[];
  work_seconds: number;
  state: string;
  gps: string;
  room: string;
  coordinates: string | null;
  kills: number;
  targets: number;
  recovered: boolean;
  waves: number;
  deployment_disabled: boolean;
};

type Data = {
  status: string;
  completed: number;
  cooldown: number;
  active: Mission | null;
  offers: Mission[];
};

const missionTabs = [
  { id: 't1', label: 'T1 Expedition' },
  { id: 't2', label: 'T2 Expedition' },
  { id: 't3', label: 'T3 Expedition' },
  { id: 'syndicate', label: 'Syndicate Signal' },
  { id: 'lavaland', label: 'Lavaland Anomalies' },
  { id: 'science', label: 'Science' },
] as const;

const missionTab = (mission: Mission) => {
  if (mission.kind === 'xenomorph') {
    return 'science';
  }
  if (mission.kind === 'siege') {
    return 'syndicate';
  }
  if (mission.kind === 'necropolis') {
    return 'lavaland';
  }
  return `t${mission.difficulty}`;
};

export const ExpeditionConsole = () => {
  const { act, data } = useBackend<Data>();
  const { active, offers, status, completed, cooldown } = data;
  const [selectedTab, setSelectedTab] = useState(
    active ? missionTab(active) : 't1',
  );
  const showActive = active && missionTab(active) === selectedTab;
  const visibleOffers = offers.filter(
    (mission) =>
      missionTab(mission) === selectedTab && mission.id !== active?.id,
  );
  return (
    <Window width={780} height={720} title="Central Command Assignments">
      <Window.Content scrollable>
        <NoticeBox>{status}</NoticeBox>
        <Section title={`Central Command Tasking — ${completed} completed`}>
          <Box>
            Review your orders and prepare before acknowledging an assignment.
            Field operations require a GPS, suitable protection, and your own
            return transport. Station defence orders provide a room and tracking
            signal when contact is confirmed. All terminals share one active
            assignment. Reward-bearing assignments release one listed requisition on completion;
            collect it beside the terminal.
          </Box>
          {cooldown > 0 && (
            <Box mt={1} color="average">
              Next departure in {cooldown} seconds.
            </Box>
          )}
        </Section>
        <Tabs fluid>
          {missionTabs.map((tab) => (
            <Tabs.Tab
              key={tab.id}
              selected={selectedTab === tab.id}
              onClick={() => setSelectedTab(tab.id)}
            >
              {tab.label}
            </Tabs.Tab>
          ))}
        </Tabs>
        {active && !showActive && (
          <NoticeBox>
            Active assignment: {active.title}. Finish or withdraw before
            accepting another assignment.
            <Box mt={1}>
              <Button onClick={() => setSelectedTab(missionTab(active))}>
                View Active Assignment
              </Button>
            </Box>
          </NoticeBox>
        )}
        {showActive ? (
          <Section title={active.title}>
            <MissionDetails mission={active} />
            <LabeledList>
              <LabeledList.Item label="State">{active.state}</LabeledList.Item>
              <LabeledList.Item label="Room">{active.room}</LabeledList.Item>
              <LabeledList.Item label="GPS signal">
                {active.gps}
              </LabeledList.Item>
              <LabeledList.Item label="Coordinates (X, Y, Z)">
                {active.coordinates || 'Beacon unavailable'}
              </LabeledList.Item>
              {active.targets > 0 && (
                <LabeledList.Item label="Hostiles eliminated">
                  {active.kills} / {active.targets}
                </LabeledList.Item>
              )}
              {(active.kind === 'siege' ||
                active.kind === 'necropolis' ||
                active.kind === 'xenomorph') && (
                <>
                  <LabeledList.Item label="Waves deployed">
                    {active.waves} / 3
                  </LabeledList.Item>
                  <LabeledList.Item label="Breach reinforcement source">
                    {active.deployment_disabled
                      ? 'Disabled / exhausted'
                      : 'Active'}
                  </LabeledList.Item>
                </>
              )}
            </LabeledList>
            {active.kind === 'salvage' && active.recovered && (
              <NoticeBox>
                Bring the flight recorder back and use it on this console.
              </NoticeBox>
            )}
            {active.state === 'failed' && (
              <NoticeBox danger>
                The objective or a required target was lost. Abandon this
                expedition to try another.
              </NoticeBox>
            )}
            {active.state === 'complete' && (
              <Section title="Central Command Requisition Clearance">
                <Stack vertical>
                  {active.rewards.map((reward) => (
                    <Stack.Item key={reward.id}>
                      <Button
                        fluid
                        icon="gift"
                        color="good"
                        onClick={() =>
                          act('claim', { id: active.id, reward: reward.id })
                        }
                      >
                        {reward.name}
                      </Button>
                      <Box mt={1} color="label">
                        {reward.description}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            )}
            <Box mt={2}>
              <Button.Confirm
                color="bad"
                icon="ban"
                onClick={() => act('abandon', { id: active.id })}
              >
                Withdraw from Assignment
              </Button.Confirm>
              <Box mt={1} color="label">
                Withdrawal forfeits requisition clearance. Central Command will
                issue new tasking after one minute.
              </Box>
            </Box>
          </Section>
        ) : (
          visibleOffers.map((mission) => (
            <Section key={mission.id} title={mission.title}>
              <MissionDetails mission={mission} />
              <Button
                icon="rocket"
                disabled={!!active || cooldown > 0}
                onClick={() => act('accept', { id: mission.id })}
              >
                Accept Assignment
              </Button>
            </Section>
          ))
        )}
      </Window.Content>
    </Window>
  );
};

const MissionDetails = ({ mission }: { mission: Mission }) => (
  <Box mb={2}>
    <Box mb={1} color="label">
      Issued by {mission.issuer}
    </Box>
    <Box mb={1}>{mission.description}</Box>
    <Box bold mb={1}>
      Field orders
    </Box>
    {mission.orders.map((order, index) => (
      <Box key={order} mb={1}>
        {index + 1}. {order}
      </Box>
    ))}
    <Box color="good">Requisition reserve: {mission.reward_theme}</Box>
    <Box color="average">
      Difficulty: {mission.difficulty}/4
      {mission.kind === 'xenomorph'
        ? ' · Science T4 mythical rewards · Queen immediately · 3 waves of 2–4 xenomorphs, 30 seconds apart'
        : mission.kind === 'siege' || mission.kind === 'necropolis'
        ? ` · Mythical rewards · 45-second preparation · waves: ${mission.kind === 'necropolis' ? '3 / 4 / 5 creatures' : '2 / 2 / 3 boarders'}`
        : ` · Field work: ${mission.work_seconds} seconds`}
    </Box>
    <Box color="label">
      Authorized selection:{' '}
      {mission.rewards.length
        ? mission.rewards.map((reward) => reward.name).join(', ')
        : 'None'}
      .
    </Box>
  </Box>
);
